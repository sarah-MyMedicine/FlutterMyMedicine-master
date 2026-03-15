const express = require('express');
const router = express.Router();
const crypto = require('crypto');
const User = require('../models/User');
const LinkInvitation = require('../models/LinkInvitation');
const EmergencyAlert = require('../models/EmergencyAlert');
const { sendPushNotification } = require('../services/push_service');
const { authMiddleware } = require('../middleware/auth');

// ============ GENERATE INVITATION CODE ============

router.post('/generate-invitation', authMiddleware, async (req, res) => {
  try {
    const { username } = req.body;

    // Find patient user
    const patient = await User.findOne({ username: username.toLowerCase() });
    if (!patient) {
      return res.status(404).json({ message: 'User not found' });
    }

    if (patient.userType !== 'patient') {
      return res.status(400).json({ message: 'Only patients can generate invitation codes' });
    }

    // Generate 6-character alphanumeric code
    const code = crypto.randomBytes(3).toString('hex').toUpperCase();

    // Create invitation
    const invitation = new LinkInvitation({
      invitationCode: code,
      patientId: patient._id,
      patientUsername: patient.username,
      patientName: patient.name,
      status: 'pending',
    });

    await invitation.save();

    res.status(201).json({
      success: true,
      invitationCode: code,
      expiresAt: invitation.expiresAt,
    });
  } catch (error) {
    console.error('[Caregiver] Generate invitation error:', error);
    res.status(500).json({ message: 'Failed to generate invitation' });
  }
});

// ============ GET PENDING INVITATIONS ============

router.get('/invitations/:username', authMiddleware, async (req, res) => {
  try {
    const { username } = req.params;

    // Find caregiver user
    const caregiver = await User.findOne({ username: username.toLowerCase() });
    if (!caregiver) {
      return res.status(404).json({ message: 'User not found' });
    }

    if (caregiver.userType !== 'caregiver') {
      return res.status(400).json({ message: 'Only caregivers can view invitations' });
    }

    // Get pending invitations that are not expired
    const invitations = await LinkInvitation.find({
      status: 'pending',
      expiresAt: { $gt: new Date() },
    }).lean();

    res.json({
      success: true,
      invitations,
    });
  } catch (error) {
    console.error('[Caregiver] Get invitations error:', error);
    res.status(500).json({ message: 'Failed to get invitations' });
  }
});

// ============ ACCEPT INVITATION ============

router.post('/accept-invitation', authMiddleware, async (req, res) => {
  try {
    const { invitationCode, caregiverUsername } = req.body;

    // Validate input
    if (!invitationCode || !caregiverUsername) {
      return res.status(400).json({ message: 'Missing required fields' });
    }

    // Find invitation
    const invitation = await LinkInvitation.findOne({
      invitationCode: invitationCode.toUpperCase(),
      status: 'pending',
      expiresAt: { $gt: new Date() },
    });

    if (!invitation) {
      return res.status(404).json({ message: 'Invalid or expired invitation code' });
    }

    // Find caregiver
    const caregiver = await User.findOne({ username: caregiverUsername.toLowerCase() });
    if (!caregiver) {
      return res.status(404).json({ message: 'Caregiver not found' });
    }

    if (caregiver.userType !== 'caregiver') {
      return res.status(400).json({ message: 'User is not a caregiver' });
    }

    // Find patient
    const patient = await User.findById(invitation.patientId);
    if (!patient) {
      return res.status(404).json({ message: 'Patient not found' });
    }

    // Link patient and caregiver
    patient.caregiverId = caregiver._id;
    caregiver.patientIds.push(patient._id);

    await patient.save();
    await caregiver.save();

    // Update invitation status
    invitation.status = 'accepted';
    await invitation.save();

    res.json({
      success: true,
      message: 'Invitation accepted and linked successfully',
      patientName: patient.name,
    });
  } catch (error) {
    console.error('[Caregiver] Accept invitation error:', error);
    res.status(500).json({ message: 'Failed to accept invitation' });
  }
});

// ============ REJECT INVITATION ============

router.post('/reject-invitation', authMiddleware, async (req, res) => {
  try {
    const { invitationCode } = req.body;

    if (!invitationCode) {
      return res.status(400).json({ message: 'Invitation code required' });
    }

    const invitation = await LinkInvitation.findOne({
      invitationCode: invitationCode.toUpperCase(),
    });

    if (!invitation) {
      return res.status(404).json({ message: 'Invitation not found' });
    }

    invitation.status = 'expired';
    await invitation.save();

    res.json({
      success: true,
      message: 'Invitation rejected',
    });
  } catch (error) {
    console.error('[Caregiver] Reject invitation error:', error);
    res.status(500).json({ message: 'Failed to reject invitation' });
  }
});

// ============ GET LINKED PATIENTS ============

router.get('/patients/:caregiverUsername', authMiddleware, async (req, res) => {
  try {
    const { caregiverUsername } = req.params;

    // Find caregiver and populate patients
    const caregiver = await User.findOne({ username: caregiverUsername.toLowerCase() })
      .populate('patientIds', 'name username userType')
      .lean();

    if (!caregiver) {
      return res.status(404).json({ message: 'Caregiver not found' });
    }

    if (caregiver.userType !== 'caregiver') {
      return res.status(400).json({ message: 'User is not a caregiver' });
    }

    res.json({
      success: true,
      patients: caregiver.patientIds || [],
    });
  } catch (error) {
    console.error('[Caregiver] Get patients error:', error);
    res.status(500).json({ message: 'Failed to get patients' });
  }
});

// ============ GET LINKED CAREGIVER ============

router.get('/caregiver/:patientUsername', authMiddleware, async (req, res) => {
  try {
    const { patientUsername } = req.params;

    // Find patient and populate caregiver
    const patient = await User.findOne({ username: patientUsername.toLowerCase() })
      .populate('caregiverId', 'name username userType')
      .lean();

    if (!patient) {
      return res.status(404).json({ message: 'Patient not found' });
    }

    if (patient.userType !== 'patient') {
      return res.status(400).json({ message: 'User is not a patient' });
    }

    res.json({
      success: true,
      caregiver: patient.caregiverId || null,
    });
  } catch (error) {
    console.error('[Caregiver] Get caregiver error:', error);
    res.status(500).json({ message: 'Failed to get caregiver' });
  }
});

// ============ UNLINK CAREGIVER ============

router.post('/unlink', authMiddleware, async (req, res) => {
  try {
    const { patientUsername, caregiverUsername } = req.body;

    if (!patientUsername || !caregiverUsername) {
      return res.status(400).json({ message: 'Missing required fields' });
    }

    // Find patient and caregiver
    const patient = await User.findOne({ username: patientUsername.toLowerCase() });
    const caregiver = await User.findOne({ username: caregiverUsername.toLowerCase() });

    if (!patient || !caregiver) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Unlink
    patient.caregiverId = null;
    caregiver.patientIds = caregiver.patientIds.filter(
      (id) => !id.equals(patient._id)
    );

    await patient.save();
    await caregiver.save();

    res.json({
      success: true,
      message: 'Caregiver unlinked successfully',
    });
  } catch (error) {
    console.error('[Caregiver] Unlink error:', error);
    res.status(500).json({ message: 'Failed to unlink caregiver' });
  }
});

// ============ REGISTER/CLEAR FCM TOKEN ============

router.post('/register-fcm-token', authMiddleware, async (req, res) => {
  try {
    const { fcmToken } = req.body;
    if (!fcmToken || typeof fcmToken !== 'string') {
      return res.status(400).json({ message: 'Valid fcmToken is required' });
    }

    const user = await User.findOne({ username: req.username.toLowerCase() });
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    user.fcmToken = fcmToken;
    user.updatedAt = new Date();
    await user.save();

    res.json({ success: true, message: 'FCM token registered' });
  } catch (error) {
    console.error('[Caregiver] Register FCM token error:', error);
    res.status(500).json({ message: 'Failed to register FCM token' });
  }
});

router.post('/clear-fcm-token', authMiddleware, async (req, res) => {
  try {
    const user = await User.findOne({ username: req.username.toLowerCase() });
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    user.fcmToken = null;
    user.updatedAt = new Date();
    await user.save();

    res.json({ success: true, message: 'FCM token cleared' });
  } catch (error) {
    console.error('[Caregiver] Clear FCM token error:', error);
    res.status(500).json({ message: 'Failed to clear FCM token' });
  }
});

// ============ NOTIFY MISSED DOSES ============

router.post('/notify-missed-dose', authMiddleware, async (req, res) => {
  try {
    const { patientUsername, consecutiveMissed, medicationName } = req.body;

    if (!patientUsername || !consecutiveMissed || !medicationName) {
      return res.status(400).json({ message: 'Missing required fields' });
    }

    if (req.username !== patientUsername.toLowerCase()) {
      return res.status(403).json({ message: 'You can only send alerts for your own account' });
    }

    // Find patient and their caregiver
    const patient = await User.findOne({ username: patientUsername.toLowerCase() })
      .populate('caregiverId', 'fcmToken name username');

    if (!patient) {
      return res.status(404).json({ message: 'Patient not found' });
    }

    if (patient.userType !== 'patient') {
      return res.status(400).json({ message: 'Only patients can send missed dose alerts' });
    }

    let pushDelivered = false;

    // If patient has linked caregiver and FCM token, send push notification
    if (patient.caregiverId && patient.caregiverId.fcmToken) {
      const pushResult = await sendPushNotification({
        token: patient.caregiverId.fcmToken,
        title: 'تنبيه: جرعات دواء مفقودة',
        body: `${patient.name} فاته ${consecutiveMissed} جرعات من ${medicationName}`,
        data: {
          type: 'missed_dose',
          patientUsername: patient.username,
          patientName: patient.name,
          medicationName,
          consecutiveMissed,
        },
      });
      pushDelivered = pushResult.delivered;
      console.log(`[Caregiver] Missed-dose push result: ${JSON.stringify(pushResult)}`);
    }

    // Log the missed dose notification
    console.log(`[Caregiver] Missed doses reported: Patient=${patientUsername}, Missed=${consecutiveMissed}, Medication=${medicationName}`);

    res.json({
      success: true,
      message: 'Missed dose notification sent',
      caregiverNotified: patient.caregiverId != null,
      pushDelivered,
    });
  } catch (error) {
    console.error('[Caregiver] Notify missed doses error:', error);
    res.status(500).json({ message: 'Failed to send notification' });
  }
});

// ============ NOTIFY EMERGENCY (SIREN) ============

router.post('/notify-emergency', authMiddleware, async (req, res) => {
  try {
    const { patientUsername, message, classification } = req.body;

    if (!patientUsername) {
      return res.status(400).json({ message: 'Patient username is required' });
    }

    // Ensure patients can only send emergency alerts for themselves.
    if (req.username !== patientUsername.toLowerCase()) {
      return res.status(403).json({ message: 'You can only send alerts for your own account' });
    }

    const patient = await User.findOne({ username: patientUsername.toLowerCase() })
      .populate('caregiverId', 'name username fcmToken userType');

    if (!patient) {
      return res.status(404).json({ message: 'Patient not found' });
    }

    if (patient.userType !== 'patient') {
      return res.status(400).json({ message: 'Only patients can send emergency alerts' });
    }

    if (!patient.caregiverId) {
      return res.status(400).json({ message: 'No linked caregiver found for this patient' });
    }

    const resolvedClassification = classification || 'siren';
    const resolvedMessage =
      message ||
      `${patient.name} triggered an emergency alert and needs immediate attention.`;

    const alert = new EmergencyAlert({
      patientId: patient._id,
      caregiverId: patient.caregiverId._id,
      patientUsername: patient.username,
      patientName: patient.name,
      caregiverUsername: patient.caregiverId.username,
      caregiverName: patient.caregiverId.name,
      classification: resolvedClassification,
      message: resolvedMessage,
      status: 'unread',
    });

    await alert.save();

    let pushDelivered = false;
    if (patient.caregiverId.fcmToken) {
      const pushResult = await sendPushNotification({
        token: patient.caregiverId.fcmToken,
        title: '🚨 Siren Emergency Alert',
        body: resolvedMessage,
        data: {
          type: 'emergency_siren',
          alertId: alert._id,
          classification: resolvedClassification,
          patientUsername: patient.username,
          patientName: patient.name,
        },
      });
      pushDelivered = pushResult.delivered;
      console.log(`[Caregiver] Siren push result: ${JSON.stringify(pushResult)}`);
    }

    console.log(
      `[Caregiver] Emergency alert saved: patient=${patient.username}, caregiver=${patient.caregiverId.username}, classification=${resolvedClassification}`
    );

    res.json({
      success: true,
      message: 'Emergency alert sent to caregiver',
      alertId: alert._id,
      caregiver: {
        username: patient.caregiverId.username,
        name: patient.caregiverId.name,
      },
      classification: resolvedClassification,
      pushDelivered,
    });
  } catch (error) {
    console.error('[Caregiver] Notify emergency error:', error);
    res.status(500).json({ message: 'Failed to send emergency alert' });
  }
});

// ============ GET CAREGIVER ALERTS ============

router.get('/alerts/:caregiverUsername', authMiddleware, async (req, res) => {
  try {
    const { caregiverUsername } = req.params;

    if (req.username !== caregiverUsername.toLowerCase()) {
      return res.status(403).json({ message: 'You can only access your own alerts' });
    }

    const caregiver = await User.findOne({ username: caregiverUsername.toLowerCase() });
    if (!caregiver) {
      return res.status(404).json({ message: 'Caregiver not found' });
    }

    if (caregiver.userType !== 'caregiver') {
      return res.status(400).json({ message: 'User is not a caregiver' });
    }

    const alerts = await EmergencyAlert.find({ caregiverId: caregiver._id })
      .sort({ createdAt: -1 })
      .limit(100)
      .lean();

    res.json({
      success: true,
      alerts,
    });
  } catch (error) {
    console.error('[Caregiver] Get alerts error:', error);
    res.status(500).json({ message: 'Failed to get alerts' });
  }
});

// ============ MARK ALERT AS READ ============

router.patch('/alerts/:alertId/read', authMiddleware, async (req, res) => {
  try {
    const { alertId } = req.params;

    const alert = await EmergencyAlert.findById(alertId);
    if (!alert) {
      return res.status(404).json({ message: 'Alert not found' });
    }

    const caregiver = await User.findById(alert.caregiverId);
    if (!caregiver || caregiver.username !== req.username) {
      return res.status(403).json({ message: 'You are not allowed to update this alert' });
    }

    alert.status = 'read';
    await alert.save();

    res.json({
      success: true,
      message: 'Alert marked as read',
    });
  } catch (error) {
    console.error('[Caregiver] Mark alert read error:', error);
    res.status(500).json({ message: 'Failed to mark alert as read' });
  }
});

module.exports = router;
