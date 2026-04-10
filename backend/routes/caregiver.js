const express = require('express');
const crypto = require('crypto');
const { sendPushNotification } = require('../services/push_service');
const { authMiddleware } = require('../middleware/auth');
const store = require('../services/firestore_store');

const router = express.Router();

router.post('/generate-invitation', authMiddleware, async (req, res) => {
  try {
    const { username } = req.body;
    const patient = await store.getUserByUsername(String(username || '').trim().toLowerCase());
    if (!patient) {
      return res.status(404).json({ message: 'User not found' });
    }
    if (patient.userType !== 'patient') {
      return res.status(400).json({ message: 'Only patients can generate invitation codes' });
    }

    const code = crypto.randomBytes(3).toString('hex').toUpperCase();
    const invitation = await store.createInvitation({
      invitationCode: code,
      patientId: patient.id,
      patientUsername: patient.username,
      patientName: patient.name,
    });

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

router.get('/invitations/:username', authMiddleware, async (req, res) => {
  try {
    const caregiver = await store.getUserByUsername(req.params.username.toLowerCase());
    if (!caregiver) {
      return res.status(404).json({ message: 'User not found' });
    }
    if (caregiver.userType !== 'caregiver') {
      return res.status(400).json({ message: 'Only caregivers can view invitations' });
    }

    const invitations = (await store.listInvitations()).filter((invitation) => {
      return invitation.status === 'pending' && new Date(invitation.expiresAt) > new Date();
    });

    res.json({ success: true, invitations });
  } catch (error) {
    console.error('[Caregiver] Get invitations error:', error);
    res.status(500).json({ message: 'Failed to get invitations' });
  }
});

router.post('/accept-invitation', authMiddleware, async (req, res) => {
  try {
    const { invitationCode, caregiverUsername } = req.body;
    if (!invitationCode || !caregiverUsername) {
      return res.status(400).json({ message: 'Missing required fields' });
    }

    const invitation = await store.getInvitationByCode(invitationCode);
    if (!invitation || invitation.status !== 'pending' || new Date(invitation.expiresAt) <= new Date()) {
      return res.status(404).json({ message: 'Invalid or expired invitation code' });
    }

    const caregiver = await store.getUserByUsername(caregiverUsername.toLowerCase());
    if (!caregiver) {
      return res.status(404).json({ message: 'Caregiver not found' });
    }
    if (caregiver.userType !== 'caregiver') {
      return res.status(400).json({ message: 'User is not a caregiver' });
    }

    const patient = await store.getUserById(invitation.patientId);
    if (!patient) {
      return res.status(404).json({ message: 'Patient not found' });
    }

    const patientIds = Array.isArray(caregiver.patientIds) ? caregiver.patientIds : [];
    if (!patientIds.includes(patient.id)) {
      patientIds.push(patient.id);
    }

    await store.updateUser(patient.id, { caregiverId: caregiver.id });
    await store.updateUser(caregiver.id, { patientIds });
    await store.updateInvitation(invitation.id, { status: 'accepted' });

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

router.post('/reject-invitation', authMiddleware, async (req, res) => {
  try {
    const { invitationCode } = req.body;
    if (!invitationCode) {
      return res.status(400).json({ message: 'Invitation code required' });
    }

    const invitation = await store.getInvitationByCode(invitationCode);
    if (!invitation) {
      return res.status(404).json({ message: 'Invitation not found' });
    }

    await store.updateInvitation(invitation.id, { status: 'expired' });
    res.json({ success: true, message: 'Invitation rejected' });
  } catch (error) {
    console.error('[Caregiver] Reject invitation error:', error);
    res.status(500).json({ message: 'Failed to reject invitation' });
  }
});

router.get('/patients/:caregiverUsername', authMiddleware, async (req, res) => {
  try {
    const caregiver = await store.getUserByUsername(req.params.caregiverUsername.toLowerCase());
    if (!caregiver) {
      return res.status(404).json({ message: 'Caregiver not found' });
    }
    if (caregiver.userType !== 'caregiver') {
      return res.status(400).json({ message: 'User is not a caregiver' });
    }

    const patients = await Promise.all(
      (caregiver.patientIds || []).map((patientId) => store.getUserById(patientId)),
    );

    res.json({
      success: true,
      patients: patients.filter(Boolean).map((patient) => ({
        id: patient.id,
        name: patient.name,
        username: patient.username,
        userType: patient.userType,
      })),
    });
  } catch (error) {
    console.error('[Caregiver] Get patients error:', error);
    res.status(500).json({ message: 'Failed to get patients' });
  }
});

router.get('/caregiver/:patientUsername', authMiddleware, async (req, res) => {
  try {
    const patient = await store.getUserByUsername(req.params.patientUsername.toLowerCase());
    if (!patient) {
      return res.status(404).json({ message: 'Patient not found' });
    }
    if (patient.userType !== 'patient') {
      return res.status(400).json({ message: 'User is not a patient' });
    }

    const caregiver = patient.caregiverId ? await store.getUserById(patient.caregiverId) : null;
    res.json({
      success: true,
      caregiver: caregiver
        ? {
            id: caregiver.id,
            name: caregiver.name,
            username: caregiver.username,
            userType: caregiver.userType,
          }
        : null,
    });
  } catch (error) {
    console.error('[Caregiver] Get caregiver error:', error);
    res.status(500).json({ message: 'Failed to get caregiver' });
  }
});

router.post('/unlink', authMiddleware, async (req, res) => {
  try {
    const { patientUsername, caregiverUsername } = req.body;
    if (!patientUsername || !caregiverUsername) {
      return res.status(400).json({ message: 'Missing required fields' });
    }

    const patient = await store.getUserByUsername(patientUsername.toLowerCase());
    const caregiver = await store.getUserByUsername(caregiverUsername.toLowerCase());
    if (!patient || !caregiver) {
      return res.status(404).json({ message: 'User not found' });
    }

    const patientIds = (caregiver.patientIds || []).filter((id) => id !== patient.id);
    await store.updateUser(patient.id, { caregiverId: null });
    await store.updateUser(caregiver.id, { patientIds });

    res.json({ success: true, message: 'Caregiver unlinked successfully' });
  } catch (error) {
    console.error('[Caregiver] Unlink error:', error);
    res.status(500).json({ message: 'Failed to unlink caregiver' });
  }
});

router.post('/register-fcm-token', authMiddleware, async (req, res) => {
  try {
    const { fcmToken } = req.body;
    if (!fcmToken || typeof fcmToken !== 'string') {
      return res.status(400).json({ message: 'Valid fcmToken is required' });
    }

    const user = await store.getUserByUsername(req.username.toLowerCase());
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    await store.updateUser(user.id, { fcmToken });
    res.json({ success: true, message: 'FCM token registered' });
  } catch (error) {
    console.error('[Caregiver] Register FCM token error:', error);
    res.status(500).json({ message: 'Failed to register FCM token' });
  }
});

router.post('/clear-fcm-token', authMiddleware, async (req, res) => {
  try {
    const user = await store.getUserByUsername(req.username.toLowerCase());
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    await store.updateUser(user.id, { fcmToken: null });
    res.json({ success: true, message: 'FCM token cleared' });
  } catch (error) {
    console.error('[Caregiver] Clear FCM token error:', error);
    res.status(500).json({ message: 'Failed to clear FCM token' });
  }
});

router.post('/notify-missed-dose', authMiddleware, async (req, res) => {
  try {
    const { patientUsername, consecutiveMissed, medicationName } = req.body;
    if (!patientUsername || !consecutiveMissed || !medicationName) {
      return res.status(400).json({ message: 'Missing required fields' });
    }
    if (req.username !== patientUsername.toLowerCase()) {
      return res.status(403).json({ message: 'You can only send alerts for your own account' });
    }

    const patient = await store.getUserByUsername(patientUsername.toLowerCase());
    if (!patient) {
      return res.status(404).json({ message: 'Patient not found' });
    }
    if (patient.userType !== 'patient') {
      return res.status(400).json({ message: 'Only patients can send missed dose alerts' });
    }

    const caregiver = patient.caregiverId ? await store.getUserById(patient.caregiverId) : null;
    let pushDelivered = false;

    if (caregiver?.fcmToken) {
      const pushResult = await sendPushNotification({
        token: caregiver.fcmToken,
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
    }

    res.json({
      success: true,
      message: 'Missed dose notification sent',
      caregiverNotified: caregiver != null,
      pushDelivered,
    });
  } catch (error) {
    console.error('[Caregiver] Notify missed doses error:', error);
    res.status(500).json({ message: 'Failed to send notification' });
  }
});

router.post('/notify-emergency', authMiddleware, async (req, res) => {
  try {
    const { patientUsername, message, classification } = req.body;
    if (!patientUsername) {
      return res.status(400).json({ message: 'Patient username is required' });
    }
    if (req.username !== patientUsername.toLowerCase()) {
      return res.status(403).json({ message: 'You can only send alerts for your own account' });
    }

    const patient = await store.getUserByUsername(patientUsername.toLowerCase());
    if (!patient) {
      return res.status(404).json({ message: 'Patient not found' });
    }
    if (patient.userType !== 'patient') {
      return res.status(400).json({ message: 'Only patients can send emergency alerts' });
    }

    const caregiver = patient.caregiverId ? await store.getUserById(patient.caregiverId) : null;
    if (!caregiver) {
      return res.status(400).json({ message: 'No linked caregiver found for this patient' });
    }

    const resolvedClassification = classification || 'siren';
    const resolvedMessage = message || `${patient.name} triggered an emergency alert and needs immediate attention.`;

    const alert = await store.createAlert({
      patientId: patient.id,
      caregiverId: caregiver.id,
      patientUsername: patient.username,
      patientName: patient.name,
      caregiverUsername: caregiver.username,
      caregiverName: caregiver.name,
      classification: resolvedClassification,
      message: resolvedMessage,
    });

    let pushDelivered = false;
    if (caregiver.fcmToken) {
      const pushResult = await sendPushNotification({
        token: caregiver.fcmToken,
        title: '🚨 Siren Emergency Alert',
        body: resolvedMessage,
        data: {
          type: 'emergency_siren',
          alertId: alert.id,
          classification: resolvedClassification,
          patientUsername: patient.username,
          patientName: patient.name,
        },
      });
      pushDelivered = pushResult.delivered;
    }

    res.json({
      success: true,
      message: 'Emergency alert sent to caregiver',
      alertId: alert.id,
      caregiver: {
        username: caregiver.username,
        name: caregiver.name,
      },
      classification: resolvedClassification,
      pushDelivered,
    });
  } catch (error) {
    console.error('[Caregiver] Notify emergency error:', error);
    res.status(500).json({ message: 'Failed to send emergency alert' });
  }
});

router.get('/alerts/:caregiverUsername', authMiddleware, async (req, res) => {
  try {
    const { caregiverUsername } = req.params;
    if (req.username !== caregiverUsername.toLowerCase()) {
      return res.status(403).json({ message: 'You can only access your own alerts' });
    }

    const caregiver = await store.getUserByUsername(caregiverUsername.toLowerCase());
    if (!caregiver) {
      return res.status(404).json({ message: 'Caregiver not found' });
    }
    if (caregiver.userType !== 'caregiver') {
      return res.status(400).json({ message: 'User is not a caregiver' });
    }

    const alerts = await store.listAlertsByCaregiverId(caregiver.id);
    res.json({ success: true, alerts: alerts.slice(0, 100) });
  } catch (error) {
    console.error('[Caregiver] Get alerts error:', error);
    res.status(500).json({ message: 'Failed to get alerts' });
  }
});

router.patch('/alerts/:alertId/read', authMiddleware, async (req, res) => {
  try {
    const alert = await store.getAlertById(req.params.alertId);
    if (!alert) {
      return res.status(404).json({ message: 'Alert not found' });
    }

    const caregiver = await store.getUserById(alert.caregiverId);
    if (!caregiver || caregiver.username !== req.username) {
      return res.status(403).json({ message: 'You are not allowed to update this alert' });
    }

    await store.updateAlert(alert.id, { status: 'read' });
    res.json({ success: true, message: 'Alert marked as read' });
  } catch (error) {
    console.error('[Caregiver] Mark alert read error:', error);
    res.status(500).json({ message: 'Failed to mark alert as read' });
  }
});

module.exports = router;
