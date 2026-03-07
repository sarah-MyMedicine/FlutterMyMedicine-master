const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';

// ============ REGISTER ============

router.post('/register', async (req, res) => {
  try {
    const { username, password, name, userType } = req.body;

    // Validate input
    if (!username || !password || !name || !userType) {
      return res.status(400).json({ message: 'Missing required fields' });
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
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    // Check password
    const validPassword = await bcrypt.compare(password, user.password);
    if (!validPassword) {
      return res.status(401).json({ message: 'Invalid credentials' });
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

// ============ LOGOUT ============

router.post('/logout', (req, res) => {
  // Since we're using JWT, logout is handled on client side
  // by removing the token from storage
  res.json({ success: true, message: 'Logged out successfully' });
});

// ============ PASSWORD RESET ============

router.post('/reset-password', async (req, res) => {
  try {
    const { username, newPassword } = req.body;
    
    if (!username || !newPassword) {
      return res.status(400).json({ message: 'Username and new password required' });
    }
    
    if (newPassword.length < 6) {
      return res.status(400).json({ message: 'Password must be at least 6 characters' });
    }
    
    const user = await User.findOne({ username: username.toLowerCase() });
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    // Hash new password
    const hashedPassword = await bcrypt.hash(newPassword, 10);
    user.password = hashedPassword;
    user.updatedAt = Date.now();
    await user.save();
    
    console.log(`[Auth] Password reset for user: ${username}`);
    
    res.json({ 
      success: true, 
      message: 'Password reset successfully',
      username: user.username
    });
  } catch (error) {
    console.error('[Auth] Password reset error:', error);
    res.status(500).json({ message: 'Password reset failed' });
  }
});

module.exports = router;
