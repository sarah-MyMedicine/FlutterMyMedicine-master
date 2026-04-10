const express = require('express');
const store = require('../services/firestore_store');
const { config } = require('../config/env');

const router = express.Router();

async function withRelationships(user) {
  if (!user) return null;

  const caregiver = user.caregiverId ? await store.getUserById(user.caregiverId) : null;
  const patients = await Promise.all((user.patientIds || []).map((patientId) => store.getUserById(patientId)));

  return {
    ...user,
    password: undefined,
    caregiverId: caregiver
      ? {
          id: caregiver.id,
          name: caregiver.name,
          username: caregiver.username,
          userType: caregiver.userType,
          createdAt: caregiver.createdAt,
        }
      : null,
    patientIds: patients.filter(Boolean).map((patient) => ({
      id: patient.id,
      name: patient.name,
      username: patient.username,
      userType: patient.userType,
      createdAt: patient.createdAt,
    })),
  };
}

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
    const users = await Promise.all((await store.listUsers()).map(withRelationships));
    
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
    const users = await store.listUsers();
    const invitations = await store.listInvitations();
    const totalUsers = users.length;
    const patientsCount = users.filter((user) => user.userType === 'patient').length;
    const caregiversCount = users.filter((user) => user.userType === 'caregiver').length;
    const linkedPatientsCount = users.filter((user) => user.userType === 'patient' && !!user.caregiverId).length;
    const pendingInvitations = invitations.filter((invitation) => {
      return invitation.status === 'pending' && new Date(invitation.expiresAt) > new Date();
    }).length;
    
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
    const rawUser = await store.getUserByUsername(req.params.username.toLowerCase());
    const user = await withRelationships(rawUser);
    
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    let invitations = [];
    if (user.userType === 'patient') {
      invitations = (await store.listInvitations())
        .filter((invitation) => invitation.patientId === user.id)
        .slice(0, 10);
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
    
    const users = (await store.searchUsers(String(query))).slice(0, 20).map((user) => ({
      ...user,
      password: undefined,
    }));
    
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
    const user = await store.getUserByUsername(username);
    
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    if (user.userType === 'caregiver' && user.patientIds.length > 0) {
      await Promise.all(user.patientIds.map((patientId) => store.updateUser(patientId, { caregiverId: null })));
    }
    
    if (user.userType === 'patient' && user.caregiverId) {
      const caregiver = await store.getUserById(user.caregiverId);
      if (caregiver) {
        await store.updateUser(caregiver.id, {
          patientIds: (caregiver.patientIds || []).filter((patientId) => patientId !== user.id),
        });
      }
    }
    
    await store.deleteInvitationsForPatient(user.id);
    await store.deleteUser(user.id);
    
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
    const usersById = new Map((await store.listUsers()).map((user) => [user.id, user]));
    let invitations = await store.listInvitations();
    if (status) {
      invitations = invitations.filter((invitation) => invitation.status === status);
    }
    invitations = invitations.slice(0, limit).map((invitation) => ({
      ...invitation,
      patientId: usersById.get(invitation.patientId)
        ? {
            id: invitation.patientId,
            name: usersById.get(invitation.patientId).name,
            username: usersById.get(invitation.patientId).username,
            userType: usersById.get(invitation.patientId).userType,
          }
        : null,
    }));
    
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
    
    const user = await store.getUserByUsername(req.params.username.toLowerCase());
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    const updates = { userType };
    if (userType === 'caregiver') {
      updates.caregiverId = null;
    } else {
      updates.patientIds = [];
    }
    await store.updateUser(user.id, updates);
    
    res.json({
      success: true,
      message: `User type updated to ${userType}`,
      user: {
        username: user.username,
        name: user.name,
        userType
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
    
    const recentUsers = (await store.listUsers())
      .filter((user) => new Date(user.createdAt) >= startDate)
      .map((user) => ({
        id: user.id,
        username: user.username,
        name: user.name,
        userType: user.userType,
        createdAt: user.createdAt,
      }));

    const usersById = new Map((await store.listUsers()).map((user) => [user.id, user]));
    const recentInvitations = (await store.listInvitations())
      .filter((invitation) => new Date(invitation.createdAt) >= startDate)
      .map((invitation) => ({
        ...invitation,
        patientId: usersById.get(invitation.patientId)
          ? {
              id: invitation.patientId,
              name: usersById.get(invitation.patientId).name,
              username: usersById.get(invitation.patientId).username,
            }
          : null,
      }));
    
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
