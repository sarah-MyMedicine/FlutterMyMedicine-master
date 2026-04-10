const express = require('express');
const router = express.Router();

const { authMiddleware } = require('../middleware/auth');
const store = require('../services/firestore_store');

router.get('/', authMiddleware, async (req, res) => {
  try {
    const user = await store.getUserById(req.userId);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.json({
      success: true,
      data: user.patientData ?? {},
      updatedAt: user.updatedAt,
    });
  } catch (error) {
    console.error('[PatientData] GET error:', error);
    res.status(500).json({ message: 'Failed to fetch patient data' });
  }
});

router.put('/', authMiddleware, async (req, res) => {
  try {
    const { data } = req.body;

    if (data == null || typeof data !== 'object' || Array.isArray(data)) {
      return res.status(400).json({ message: 'Invalid data payload' });
    }

    const user = await store.getUserById(req.userId);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    const updated = await store.updateUser(req.userId, {
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

module.exports = router;
