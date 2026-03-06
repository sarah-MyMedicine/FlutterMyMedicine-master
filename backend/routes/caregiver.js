const express = require('express');
const router = express.Router();
const crypto = require('crypto');
const User = require('../models/User');
const LinkInvitation = require('../models/LinkInvitation');
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

// ============ NOTIFY MISSED DOSES ============

router.post('/notify-missed-dose', authMiddleware, async (req, res) => {
  try {
    const { patientUsername, consecutiveMissed, medicationName } = req.body;

    if (!patientUsername || !consecutiveMissed || !medicationName) {
      return res.status(400).json({ message: 'Missing required fields' });
    }

    // Find patient and their caregiver
    const patient = await User.findOne({ username: patientUsername.toLowerCase() })
      .populate('caregiverId', 'fcmToken name username');

    if (!patient) {
      return res.status(404).json({ message: 'Patient not found' });
    }

    // If patient has linked caregiver and FCM token, send notification
    if (patient.caregiverId && patient.caregiverId.fcmToken) {
      // TODO: Implement FCM push notification
      // sendPushNotification(patient.caregiverId.fcmToken, {
      //   title: 'تنبيه: جرعات دواء مفقودة',
      //   body: `${patient.name} فاته ${consecutiveMissed} جرعات من ${medicationName}`,
      // });
      
      console.log(`[Caregiver] Notification would be sent to caregiver: ${patient.caregiverId.username}`);
    }

    // Log the missed dose notification
    console.log(`[Caregiver] Missed doses reported: Patient=${patientUsername}, Missed=${consecutiveMissed}, Medication=${medicationName}`);

    res.json({
      success: true,
      message: 'Missed dose notification sent',
      caregiverNotified: patient.caregiverId != null,
    });
  } catch (error) {
    console.error('[Caregiver] Notify missed doses error:', error);
    res.status(500).json({ message: 'Failed to send notification' });
  }
});

module.exports = router;
