const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const rateLimit = require('express-rate-limit');
const { config } = require('../config/env');
const {
  createCustomAuthToken,
  verifyFirebaseIdToken,
  upsertEmailPasswordUser,
  signInWithEmailPassword,
  generatePasswordResetLink,
  triggerFirebasePasswordResetEmail,
} = require('../services/firebase_admin_service');
const { sendPasswordResetEmail } = require('../services/email_service');
const store = require('../services/firestore_store');

const router = express.Router();
const JWT_SECRET = config.jwtSecret;

// Rate limiter: max 5 password-reset requests per IP per 15 minutes.
// Trust-proxy is already set in server.js so req.ip is the real client IP.
const passwordResetLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  standardHeaders: true,
  legacyHeaders: false,
  message: { message: 'Too many password reset requests. Please try again in 15 minutes.' },
});

function normalizeEmail(rawEmail) {
  if (!rawEmail) return null;
  const normalized = String(rawEmail).trim().toLowerCase();
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(normalized)) {
    return null;
  }
  return normalized;
}

function isEmailIdentifier(value) {
  return typeof value === 'string' && value.includes('@');
}

function sanitizeUsernameCandidate(value) {
  const cleaned = String(value || '')
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9._]/g, '_')
    .replace(/_+/g, '_')
    .replace(/^[_\.]+|[_\.]+$/g, '');

  if (cleaned.length >= 3) {
    return cleaned.slice(0, 30);
  }

  return `${cleaned.padEnd(3, 'x')}`.slice(0, 30);
}

async function generateUniqueUsername(baseValue) {
  const base = sanitizeUsernameCandidate(baseValue);
  let candidate = base;
  let counter = 1;

  while (await store.getUserByUsername(candidate)) {
    const suffix = `${counter}`;
    const trimmedBase = base.slice(0, Math.max(3, 30 - suffix.length));
    candidate = `${trimmedBase}${suffix}`;
    counter += 1;
  }

  return candidate;
}

function createBackendToken(user) {
  return jwt.sign(
    { userId: user.id, username: user.username },
    JWT_SECRET,
    { expiresIn: '30d' },
  );
}

async function buildAuthPayload(user) {
  const firebaseUid = user.firebaseUid || `user_${user.id}`;
  if (user.firebaseUid !== firebaseUid) {
    user = await store.updateUser(user.id, { firebaseUid });
  }

  const firebaseCustomToken = await createCustomAuthToken({
    uid: firebaseUid,
    claims: {
      userId: user.id,
      username: user.username,
      userType: user.userType,
    },
  });

  return {
    success: true,
    userId: user.id,
    username: user.username,
    email: user.email,
    name: user.name,
    userType: user.userType,
    phoneNumber: user.phoneNumber,
    token: createBackendToken(user),
    firebaseCustomToken,
  };
}

function isFirebaseConflictError(error) {
  return error?.code === 'auth/email-already-exists' || error?.code === 'auth/uid-already-exists';
}

async function syncFirebasePasswordAccount(user, password) {
  if (!user?.email) {
    throw new Error('Email is required for Firebase password sign-in');
  }

  const firebaseUser = await upsertEmailPasswordUser({
    uid: user.firebaseUid || undefined,
    email: user.email,
    password,
    displayName: user.name || user.username,
  });

  const updates = {};
  if (user.firebaseUid !== firebaseUser.uid) {
    updates.firebaseUid = firebaseUser.uid;
  }
  if (user.authProvider !== 'firebase_password') {
    updates.authProvider = 'firebase_password';
  }
  if (user.password) {
    updates.password = null;
  }

  if (Object.keys(updates).length === 0) {
    return user;
  }

  return store.updateUser(user.id, updates);
}

router.post('/register', async (req, res) => {
  try {
    const { username, email, password, name, userType } = req.body;

    if (!username || !email || !password || !name || !userType) {
      return res.status(400).json({ message: 'Missing required fields' });
    }
    if (userType !== 'patient' && userType !== 'caregiver') {
      return res.status(400).json({ message: 'Invalid user type' });
    }
    if (password.length < 6) {
      return res.status(400).json({ message: 'Password must be at least 6 characters' });
    }

    const normalizedUsername = String(username).trim().toLowerCase();
    const normalizedEmail = normalizeEmail(email);
    if (!normalizedEmail) {
      return res.status(400).json({ message: 'Valid email is required' });
    }

    const existingUser = await store.getUserByUsername(normalizedUsername);
    if (existingUser) {
      return res.status(400).json({ message: 'Username already exists' });
    }
    if (await store.getUserByEmail(normalizedEmail)) {
      return res.status(400).json({ message: 'Email already exists' });
    }

    const firebaseUser = await upsertEmailPasswordUser({
      email: normalizedEmail,
      password,
      displayName: name,
    });

    const user = await store.createUser({
      username: normalizedUsername,
      email: normalizedEmail,
      password: null,
      name,
      userType,
      authProvider: 'firebase_password',
      firebaseUid: firebaseUser.uid,
    });

    res.status(201).json(await buildAuthPayload(user));
  } catch (error) {
    console.error('[Auth] Register error:', error);
    if (isFirebaseConflictError(error)) {
      return res.status(400).json({ message: 'Email already exists' });
    }
    res.status(500).json({ message: 'Registration failed' });
  }
});

router.post('/login', async (req, res) => {
  try {
    const { username, password } = req.body;
    if (!username || !password) {
      return res.status(400).json({ message: 'Username or email and password required' });
    }

    const normalizedIdentifier = String(username).trim().toLowerCase();
    const user = isEmailIdentifier(normalizedIdentifier)
      ? await store.getUserByEmail(normalizedIdentifier)
      : await store.getUserByUsername(normalizedIdentifier);
    if (!user || !user.email) {
      return res.status(401).json({ message: 'Either the username/email or password is wrong. Please try again' });
    }

    let authenticatedUser = user;

    if (user.password) {
      const validPassword = await bcrypt.compare(password, user.password);
      if (!validPassword) {
        return res.status(401).json({ message: 'Either the username/email or password is wrong. Please try again' });
      }

      authenticatedUser = await syncFirebasePasswordAccount(user, password);
    } else {
      const firebaseResponse = await signInWithEmailPassword({
        email: user.email,
        password,
      });
      const decodedToken = await verifyFirebaseIdToken(firebaseResponse.idToken);
      if (!decodedToken?.uid) {
        return res.status(401).json({ message: 'Either the username/email or password is wrong. Please try again' });
      }

      if (user.firebaseUid !== decodedToken.uid || user.authProvider !== 'firebase_password') {
        authenticatedUser = await store.updateUser(user.id, {
          firebaseUid: decodedToken.uid,
          authProvider: 'firebase_password',
        });
      }
    }

    res.json(await buildAuthPayload(authenticatedUser));
  } catch (error) {
    console.error('[Auth] Login error:', error);
    if (error.message === 'Either the username/email or password is wrong. Please try again' ||
        error.message === 'This account has been disabled' ||
        error.message === 'Too many login attempts. Please try again later') {
      return res.status(401).json({ message: error.message });
    }
    res.status(500).json({ message: 'Login failed' });
  }
});

router.post('/google', async (req, res) => {
  try {
    const { idToken } = req.body;
    if (!idToken) {
      return res.status(400).json({ message: 'Google Firebase idToken is required' });
    }

    const decodedToken = await verifyFirebaseIdToken(idToken);
    const signInProvider = decodedToken.firebase?.sign_in_provider;
    if (signInProvider !== 'google.com') {
      return res.status(401).json({ message: 'Token is not from Google Sign-In' });
    }

    const firebaseUid = decodedToken.uid;
    const email = normalizeEmail(decodedToken.email);
    if (!email) {
      return res.status(400).json({ message: 'Google account email is required' });
    }

    let user = await store.getUserByFirebaseUid(firebaseUid);
    if (!user) {
      user = await store.getUserByEmail(email);
    }

    if (user) {
      const updates = {};
      if (user.firebaseUid !== firebaseUid) {
        updates.firebaseUid = firebaseUid;
      }
      if (!user.email) {
        updates.email = email;
      }
      if (!user.name && decodedToken.name) {
        updates.name = decodedToken.name;
      }
      if (!user.authProvider) {
        updates.authProvider = 'google';
      }

      if (Object.keys(updates).length > 0) {
        user = await store.updateUser(user.id, updates);
      }
    } else {
      const baseUsername = decodedToken.email?.split('@')[0] || decodedToken.name || 'user';
      const username = await generateUniqueUsername(baseUsername);

      user = await store.createUser({
        username,
        email,
        name: decodedToken.name || username,
        userType: 'patient',
        authProvider: 'google',
        firebaseUid,
        password: null,
      });
    }

    res.json(await buildAuthPayload(user));
  } catch (error) {
    console.error('[Auth] Google sign-in error:', error);
    res.status(500).json({ message: error.message || 'Google sign-in failed' });
  }
});

router.post('/logout', (req, res) => {
  res.json({ success: true, message: 'Logged out successfully' });
});

// POST /api/auth/password-reset-link
// Generates a Firebase password-reset link via Admin SDK and sends it to the
// user's registered email address. The link is NEVER returned in the response
// to prevent account-takeover by callers who know a victim's email.
//
// Security measures:
//   1. Rate-limited: 5 req / IP / 15 min (passwordResetLimiter middleware)
//   2. Enumeration-safe: always returns 200 regardless of whether the email
//      is registered, so callers cannot discover which emails exist.
//   3. Input validated: email format checked server-side before any Firebase call.
//   4. No sensitive data in response: 500 errors never expose internal messages.
//   5. Link never leaves the server: sent via SMTP, not returned in JSON.
router.post('/password-reset-link', passwordResetLimiter, async (req, res) => {
  const SAFE_RESPONSE = {
    message: 'If this email is registered, a password reset link has been sent to it.',
  };

  try {
    const { email } = req.body;
    if (!email || typeof email !== 'string') {
      return res.status(400).json({ message: 'email is required' });
    }
    const normalized = email.trim().toLowerCase();
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(normalized)) {
      return res.status(400).json({ message: 'Invalid email address' });
    }

    let link;
    try {
      link = await generatePasswordResetLink(normalized);
    } catch (linkError) {
      if (linkError.code === 'auth/user-not-found') {
        // Silently return success — do not reveal that the email is unregistered.
        return res.json(SAFE_RESPONSE);
      }
      console.error('[Auth] generatePasswordResetLink failed, falling back to Firebase reset email:', linkError.code, linkError.message);
      try {
        await triggerFirebasePasswordResetEmail(normalized);
        return res.json(SAFE_RESPONSE);
      } catch (fallbackError) {
        console.error('[Auth] Firebase password reset email fallback failed:', fallbackError.message);
        return res.status(500).json({ message: 'Failed to process password reset request' });
      }
    }

    try {
      await sendPasswordResetEmail({ to: normalized, resetLink: link });
    } catch (emailError) {
      // Log clearly for debugging, but still return 200 to prevent enumeration.
      console.error('[Auth] sendPasswordResetEmail failed:', emailError.message);
    }

    return res.json(SAFE_RESPONSE);
  } catch (error) {
    console.error('[Auth] password-reset-link unexpected error:', error.message);
    return res.status(500).json({ message: 'Failed to process password reset request' });
  }
});

module.exports = router;
