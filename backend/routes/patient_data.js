const express = require('express');
const router = express.Router();

const { authMiddleware } = require('../middleware/auth');
const store = require('../services/firestore_store');

async function resolvePatientContext(req, res, patientUsernameParam) {
  const actor = await store.getUserById(req.userId);
  if (!actor) {
    res.status(404).json({ message: 'User not found' });
    return null;
  }

  const targetUsername = String(patientUsernameParam || req.username || '').trim().toLowerCase();
  if (!targetUsername) {
    res.status(400).json({ message: 'Patient username is required' });
    return null;
  }

  const targetUser = await store.getUserByUsername(targetUsername);
  if (!targetUser) {
    res.status(404).json({ message: 'Patient not found' });
    return null;
  }

  if (actor.username === targetUser.username) {
    return { actor, targetUser };
  }

  if (actor.userType !== 'caregiver' || targetUser.userType !== 'patient') {
    res.status(403).json({ message: 'You are not allowed to access this profile' });
    return null;
  }

  const linkedPatientIds = Array.isArray(actor.patientIds) ? actor.patientIds : [];
  if (!linkedPatientIds.includes(targetUser.id)) {
    res.status(403).json({ message: 'You are not linked to this patient' });
    return null;
  }

  return { actor, targetUser };
}

router.get('/', authMiddleware, async (req, res) => {
  try {
    const context = await resolvePatientContext(req, res, req.query.patientUsername);
    if (!context) return;

    res.json({
      success: true,
      data: context.targetUser.patientData ?? {},
      updatedAt: context.targetUser.updatedAt,
    });
  } catch (error) {
    console.error('[PatientData] GET error:', error);
    res.status(500).json({ message: 'Failed to fetch patient data' });
  }
});

router.get('/:patientUsername', authMiddleware, async (req, res) => {
  try {
    const context = await resolvePatientContext(req, res, req.params.patientUsername);
    if (!context) return;

    res.json({
      success: true,
      data: context.targetUser.patientData ?? {},
      updatedAt: context.targetUser.updatedAt,
    });
  } catch (error) {
    console.error('[PatientData] GET linked error:', error);
    res.status(500).json({ message: 'Failed to fetch patient data' });
  }
});

router.put('/', authMiddleware, async (req, res) => {
  try {
    const { data, patientUsername } = req.body;

    if (data == null || typeof data !== 'object' || Array.isArray(data)) {
      return res.status(400).json({ message: 'Invalid data payload' });
    }

    const context = await resolvePatientContext(req, res, patientUsername);
    if (!context) return;

    const updated = await store.updateUser(context.targetUser.id, {
      patientData: data,
    });

    res.json({
      success: true,
      message: 'Patient data updated successfully',
      updatedAt: updated.updatedAt,
    });
  } catch (error) {
    console.error('[PatientData] PUT error:', error);
    res.status(500).json({ message: 'Failed to save patient data' });
  }
});

router.put('/:patientUsername', authMiddleware, async (req, res) => {
  try {
    const { data } = req.body;

    if (data == null || typeof data !== 'object' || Array.isArray(data)) {
      return res.status(400).json({ message: 'Invalid data payload' });
    }

    const context = await resolvePatientContext(req, res, req.params.patientUsername);
    if (!context) return;

    const updated = await store.updateUser(context.targetUser.id, {
      patientData: data,
    });

    res.json({
      success: true,
      message: 'Patient data updated successfully',
      updatedAt: updated.updatedAt,
    });
  } catch (error) {
    console.error('[PatientData] PUT linked error:', error);
    res.status(500).json({ message: 'Failed to save patient data' });
  }
});

module.exports = router;
