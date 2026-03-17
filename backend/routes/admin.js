const express = require('express');
const router = express.Router();
const User = require('../models/User');
const LinkInvitation = require('../models/LinkInvitation');
const { config } = require('../config/env');

// Admin middleware - verify admin credentials
const adminAuth = (req, res, next) => {
  const adminKey = req.headers['x-admin-key'];
  if (!config.adminApiKey || adminKey !== config.adminApiKey) {
    return res.status(403).json({ message: 'Unauthorized - Invalid admin key' });
  }
  next();
};

// ============ GET ALL USERS ============
// GET /api/admin/users
router.get('/users', adminAuth, async (req, res) => {
  try {
    const users = await User.find()
      .select('-password') // Exclude password field
      .populate('caregiverId', 'name username userType')
      .populate('patientIds', 'name username userType')
      .sort({ createdAt: -1 });
    
    res.json({
      success: true,
      count: users.length,
      users
    });
  } catch (error) {
    console.error('[Admin] Error fetching users:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// ============ GET STATISTICS ============
// GET /api/admin/stats
router.get('/stats', adminAuth, async (req, res) => {
  try {
    const totalUsers = await User.countDocuments();
    const patientsCount = await User.countDocuments({ userType: 'patient' });
    const caregiversCount = await User.countDocuments({ userType: 'caregiver' });
    const linkedPatientsCount = await User.countDocuments({ 
      userType: 'patient',
      caregiverId: { $ne: null }
    });
    const pendingInvitations = await LinkInvitation.countDocuments({ 
      status: 'pending',
      expiresAt: { $gt: new Date() }
    });
    
    const linkedPercentage = patientsCount > 0 
      ? ((linkedPatientsCount / patientsCount) * 100).toFixed(1)
      : 0;
    
    res.json({
      success: true,
      stats: {
        totalUsers,
        patients: patientsCount,
        caregivers: caregiversCount,
        linkedPatients: linkedPatientsCount,
        unlinkedPatients: patientsCount - linkedPatientsCount,
        pendingInvitations,
        linkedPercentage: `${linkedPercentage}%`,
        timestamp: new Date()
      }
    });
  } catch (error) {
    console.error('[Admin] Error fetching stats:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// ============ GET USER BY USERNAME ============
// GET /api/admin/user/:username
router.get('/user/:username', adminAuth, async (req, res) => {
  try {
    const user = await User.findOne({ username: req.params.username.toLowerCase() })
      .select('-password')
      .populate('caregiverId', 'name username userType createdAt')
      .populate('patientIds', 'name username userType createdAt');
    
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    // Get invitations if patient
    let invitations = [];
    if (user.userType === 'patient') {
      invitations = await LinkInvitation.find({ patientId: user._id })
        .sort({ createdAt: -1 })
        .limit(10);
    }
    
    res.json({ 
      success: true, 
      user,
      invitations: invitations.length > 0 ? invitations : undefined
    });
  } catch (error) {
    console.error('[Admin] Error fetching user:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// ============ SEARCH USERS ============
// GET /api/admin/search?q=query
router.get('/search', adminAuth, async (req, res) => {
  try {
    const query = req.query.q;
    if (!query) {
      return res.status(400).json({ message: 'Search query required' });
    }
    
    const users = await User.find({
      $or: [
        { username: { $regex: query, $options: 'i' } },
        { name: { $regex: query, $options: 'i' } }
      ]
    })
    .select('-password')
    .limit(20);
    
    res.json({
      success: true,
      count: users.length,
      users
    });
  } catch (error) {
    console.error('[Admin] Error searching users:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// ============ DELETE USER ============
// DELETE /api/admin/user/:username
router.delete('/user/:username', adminAuth, async (req, res) => {
  try {
    const username = req.params.username.toLowerCase();
    const user = await User.findOne({ username });
    
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    // If caregiver, remove from all patients
    if (user.userType === 'caregiver' && user.patientIds.length > 0) {
      await User.updateMany(
        { _id: { $in: user.patientIds } },
        { $set: { caregiverId: null } }
      );
    }
    
    // If patient, remove from caregiver's list
    if (user.userType === 'patient' && user.caregiverId) {
      await User.updateOne(
        { _id: user.caregiverId },
        { $pull: { patientIds: user._id } }
      );
    }
    
    // Delete all invitations related to this user
    await LinkInvitation.deleteMany({ patientId: user._id });
    
    // Delete user
    await User.deleteOne({ _id: user._id });
    
    res.json({ 
      success: true, 
      message: `User ${username} and related data deleted successfully` 
    });
  } catch (error) {
    console.error('[Admin] Error deleting user:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// ============ GET ALL INVITATIONS ============
// GET /api/admin/invitations
router.get('/invitations', adminAuth, async (req, res) => {
  try {
    const status = req.query.status; // pending, accepted, expired
    const limit = parseInt(req.query.limit) || 50;
    
    let query = {};
    if (status) {
      query.status = status;
    }
    
    const invitations = await LinkInvitation.find(query)
      .populate('patientId', 'name username userType')
      .sort({ createdAt: -1 })
      .limit(limit);
    
    res.json({
      success: true,
      count: invitations.length,
      invitations
    });
  } catch (error) {
    console.error('[Admin] Error fetching invitations:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// ============ UPDATE USER TYPE ============
// PATCH /api/admin/user/:username/type
router.patch('/user/:username/type', adminAuth, async (req, res) => {
  try {
    const { userType } = req.body;
    
    if (userType !== 'patient' && userType !== 'caregiver') {
      return res.status(400).json({ message: 'Invalid user type' });
    }
    
    const user = await User.findOne({ username: req.params.username.toLowerCase() });
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    // Clear relationships when changing type
    if (userType === 'caregiver') {
      user.caregiverId = null;
    } else {
      user.patientIds = [];
    }
    
    user.userType = userType;
    user.updatedAt = Date.now();
    await user.save();
    
    res.json({
      success: true,
      message: `User type updated to ${userType}`,
      user: {
        username: user.username,
        name: user.name,
        userType: user.userType
      }
    });
  } catch (error) {
    console.error('[Admin] Error updating user type:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// ============ GET ACTIVITY LOG ============
// GET /api/admin/activity
router.get('/activity', adminAuth, async (req, res) => {
  try {
    const days = parseInt(req.query.days) || 7;
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);
    
    // Get recent users
    const recentUsers = await User.find({ 
      createdAt: { $gte: startDate } 
    }).select('username name userType createdAt');
    
    // Get recent invitations
    const recentInvitations = await LinkInvitation.find({
      createdAt: { $gte: startDate }
    }).populate('patientId', 'name username');
    
    res.json({
      success: true,
      period: `Last ${days} days`,
      activity: {
        newUsers: recentUsers.length,
        newInvitations: recentInvitations.length,
        recentUsers,
        recentInvitations
      }
    });
  } catch (error) {
    console.error('[Admin] Error fetching activity:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;
