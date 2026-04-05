const express = require('express');
const router = express.Router();
const crypto = require('crypto');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const PhoneOtp = require('../models/PhoneOtp');
const { config } = require('../config/env');
const { createCustomAuthToken } = require('../services/firebase_admin_service');
const {
  sendAuthenticationCode,
  isWhatsAppConfigured,
} = require('../services/whatsapp_service');

const JWT_SECRET = config.jwtSecret;

function normalizePhoneNumber(rawPhoneNumber) {
  if (!rawPhoneNumber) return null;

  const trimmed = String(rawPhoneNumber).trim();
  const normalized = trimmed.startsWith('+')
    ? `+${trimmed.substring(1).replace(/\D/g, '')}`
    : `+${trimmed.replace(/\D/g, '')}`;

  if (!/^\+[1-9]\d{7,14}$/.test(normalized)) {
    return null;
  }

  return normalized;
}

function hashOtpCode(code) {
  return crypto.createHash('sha256').update(String(code)).digest('hex');
}

function generateOtpCode() {
  return `${crypto.randomInt(100000, 1000000)}`;
}

function createBackendToken(user) {
  return jwt.sign(
    { userId: user._id, username: user.username },
    JWT_SECRET,
    { expiresIn: '30d' },
  );
}

async function buildAuthPayload(user) {
  const firebaseUid = user.firebaseUid || `user_${user._id.toString()}`;
  if (!user.firebaseUid || user.firebaseUid !== firebaseUid) {
    user.firebaseUid = firebaseUid;
    await user.save();
  }

  const firebaseCustomToken = await createCustomAuthToken({
    uid: firebaseUid,
    claims: {
      userId: user._id.toString(),
      username: user.username,
      userType: user.userType,
    },
  });

  return {
    success: true,
    userId: user._id,
    username: user.username,
    name: user.name,
    userType: user.userType,
    phoneNumber: user.phoneNumber,
    token: createBackendToken(user),
    firebaseCustomToken,
  };
}

// ============ REGISTER ============

router.post('/register', async (req, res) => {
  try {
    const { username, password, name, userType, registrationSource } = req.body;

    // Validate input
    if (!username || !password || !name || !userType) {
      return res.status(400).json({ message: 'Missing required fields' });
    }

    if (registrationSource !== 'signin_button') {
      return res.status(400).json({
        message: 'Account creation is only allowed from the sign in button',
      });
    }

    if (userType !== 'patient' && userType !== 'caregiver') {
      return res.status(400).json({ message: 'Invalid user type' });
    }

    if (password.length < 6) {
      return res.status(400).json({ message: 'Password must be at least 6 characters' });
    }

    // Check if user exists
    const existingUser = await User.findOne({ username: username.toLowerCase() });
    if (existingUser) {
      return res.status(400).json({ message: 'Username already exists' });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Create user
    const user = new User({
      username: username.toLowerCase(),
      password: hashedPassword,
      name,
      userType,
    });

    await user.save();

    // Generate JWT token
    const token = jwt.sign(
      { userId: user._id, username: user.username },
      JWT_SECRET,
      { expiresIn: '30d' }
    );

    res.status(201).json({
      success: true,
      userId: user._id,
      username: user.username,
      name: user.name,
      userType: user.userType,
      token,
    });
  } catch (error) {
    console.error('[Auth] Register error:', error);

    if (error?.code === 11000) {
      if (error?.keyPattern?.username) {
        return res.status(400).json({ message: 'Username already exists' });
      }
      return res.status(400).json({
        message: 'Duplicate key conflict in database. Please contact support to reindex.',
      });
    }

    res.status(500).json({ message: 'Registration failed' });
  }
});

// ============ LOGIN ============

router.post('/login', async (req, res) => {
  try {
    const { username, password } = req.body;

    // Validate input
    if (!username || !password) {
      return res.status(400).json({ message: 'Username and password required' });
    }

    // Find user
    const user = await User.findOne({ username: username.toLowerCase() });
    if (!user) {
      return res.status(401).json({
        message: 'Either the username or password is wrong. Please try again',
      });
    }

    // Check password
    const validPassword = await bcrypt.compare(password, user.password);
    if (!validPassword) {
      return res.status(401).json({
        message: 'Either the username or password is wrong. Please try again',
      });
    }

    // Generate JWT token
    const token = jwt.sign(
      { userId: user._id, username: user.username },
      JWT_SECRET,
      { expiresIn: '30d' }
    );

    res.json({
      success: true,
      userId: user._id,
      username: user.username,
      name: user.name,
      userType: user.userType,
      token,
    });
  } catch (error) {
    console.error('[Auth] Login error:', error);
    res.status(500).json({ message: 'Login failed' });
  }
});

// ============ WHATSAPP OTP REQUEST ============

router.post('/whatsapp/request-otp', async (req, res) => {
  try {
    const {
      phoneNumber,
      purpose = 'login',
      username,
      name,
      userType,
    } = req.body;

    if (!isWhatsAppConfigured()) {
      return res.status(500).json({
        message: 'WhatsApp authentication is not configured on the server',
      });
    }

    const normalizedPhone = normalizePhoneNumber(phoneNumber);
    if (!normalizedPhone) {
      return res.status(400).json({ message: 'Invalid phone number format' });
    }

    if (purpose !== 'login' && purpose !== 'register') {
      return res.status(400).json({ message: 'Invalid OTP purpose' });
    }

    if (purpose === 'login') {
      const existingUser = await User.findOne({ phoneNumber: normalizedPhone });
      if (!existingUser) {
        return res.status(404).json({
          message: 'No account is linked to this phone number',
        });
      }
    }

    let registrationMetadata = {};
    if (purpose === 'register') {
      if (!username || !name || !userType) {
        return res.status(400).json({
          message: 'username, name, and userType are required for registration',
        });
      }

      if (userType !== 'patient' && userType !== 'caregiver') {
        return res.status(400).json({ message: 'Invalid user type' });
      }

      const normalizedUsername = String(username).trim().toLowerCase();
      const existingByUsername = await User.findOne({ username: normalizedUsername });
      if (existingByUsername) {
        return res.status(400).json({ message: 'Username already exists' });
      }

      const existingByPhone = await User.findOne({ phoneNumber: normalizedPhone });
      if (existingByPhone) {
        return res.status(400).json({
          message: 'Phone number is already linked to an existing account',
        });
      }

      registrationMetadata = {
        username: normalizedUsername,
        name: String(name).trim(),
        userType,
      };
    }

    await PhoneOtp.deleteMany({
      phoneNumber: normalizedPhone,
      purpose,
      consumedAt: null,
    });

    const code = generateOtpCode();
    const sessionId = crypto.randomUUID();
    const expiresAt = new Date(
      Date.now() + config.otpExpiryMinutes * 60 * 1000,
    );

    const delivery = await sendAuthenticationCode({
      phoneNumber: normalizedPhone,
      code,
    });

    await PhoneOtp.create({
      sessionId,
      phoneNumber: normalizedPhone,
      purpose,
      codeHash: hashOtpCode(code),
      metadata: registrationMetadata,
      providerMessageId: delivery.providerMessageId,
      expiresAt,
    });

    const response = {
      success: true,
      sessionId,
      expiresInSeconds: config.otpExpiryMinutes * 60,
    };

    if (!config.isProduction) {
      response.developmentCode = code;
    }

    res.json(response);
  } catch (error) {
    console.error('[Auth] WhatsApp OTP request error:', error);
    res.status(500).json({ message: error.message || 'Failed to send OTP' });
  }
});

// ============ WHATSAPP OTP VERIFY ============

router.post('/whatsapp/verify-otp', async (req, res) => {
  try {
    const { sessionId, code } = req.body;

    if (!sessionId || !code) {
      return res.status(400).json({ message: 'sessionId and code are required' });
    }

    const otpRecord = await PhoneOtp.findOne({ sessionId });
    if (!otpRecord || otpRecord.consumedAt != null) {
      return res.status(400).json({ message: 'OTP session is invalid or already used' });
    }

    if (otpRecord.expiresAt.getTime() < Date.now()) {
      return res.status(400).json({ message: 'OTP has expired' });
    }

    const expectedHash = Buffer.from(otpRecord.codeHash, 'hex');
    const providedHash = Buffer.from(hashOtpCode(code), 'hex');

    if (
      expectedHash.length !== providedHash.length ||
      !crypto.timingSafeEqual(expectedHash, providedHash)
    ) {
      otpRecord.attempts += 1;
      await otpRecord.save();

      if (otpRecord.attempts >= config.otpMaxAttempts) {
        await otpRecord.deleteOne();
      }

      return res.status(401).json({ message: 'Invalid OTP code' });
    }

    otpRecord.consumedAt = new Date();
    await otpRecord.save();

    let user;
    if (otpRecord.purpose === 'register') {
      const metadata = otpRecord.metadata || {};
      const randomPassword = crypto.randomBytes(24).toString('hex');
      const passwordHash = await bcrypt.hash(randomPassword, 10);

      user = await User.create({
        username: metadata.username,
        password: passwordHash,
        name: metadata.name,
        userType: metadata.userType,
        phoneNumber: otpRecord.phoneNumber,
        authProvider: 'whatsapp',
      });
    } else {
      user = await User.findOne({ phoneNumber: otpRecord.phoneNumber });
      if (!user) {
        return res.status(404).json({
          message: 'No account is linked to this phone number',
        });
      }
    }

    const payload = await buildAuthPayload(user);
    res.json(payload);
  } catch (error) {
    console.error('[Auth] WhatsApp OTP verify error:', error);
    res.status(500).json({ message: error.message || 'OTP verification failed' });
  }
});

// ============ LOGOUT ============

router.post('/logout', (req, res) => {
  // Since we're using JWT, logout is handled on client side
  // by removing the token from storage
  res.json({ success: true, message: 'Logged out successfully' });
});

module.exports = router;
