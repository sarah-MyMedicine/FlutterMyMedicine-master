const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { config } = require('../config/env');
const {
  createCustomAuthToken,
  verifyFirebaseIdToken,
  upsertEmailPasswordUser,
  signInWithEmailPassword,
} = require('../services/firebase_admin_service');
const store = require('../services/firestore_store');

const router = express.Router();
const JWT_SECRET = config.jwtSecret;

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

module.exports = router;
