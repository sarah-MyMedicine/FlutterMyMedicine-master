const mongoose = require('mongoose');

const EmergencyAlertSchema = new mongoose.Schema({
  patientId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  caregiverId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  patientUsername: {
    type: String,
    required: true,
    lowercase: true,
  },
  patientName: {
    type: String,
    required: true,
  },
  caregiverUsername: {
    type: String,
    required: true,
    lowercase: true,
  },
  caregiverName: {
    type: String,
    required: true,
  },
  classification: {
    type: String,
    enum: ['siren', 'critical', 'high', 'medium'],
    default: 'siren',
  },
  message: {
    type: String,
    required: true,
    trim: true,
  },
  status: {
    type: String,
    enum: ['unread', 'read'],
    default: 'unread',
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

module.exports = mongoose.model('EmergencyAlert', EmergencyAlertSchema);
