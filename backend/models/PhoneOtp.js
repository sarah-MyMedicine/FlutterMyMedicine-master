const mongoose = require('mongoose');

const PhoneOtpSchema = new mongoose.Schema({
  sessionId: {
    type: String,
    required: true,
    unique: true,
    index: true,
  },
  phoneNumber: {
    type: String,
    required: true,
    index: true,
  },
  purpose: {
    type: String,
    enum: ['login', 'register'],
    required: true,
  },
  codeHash: {
    type: String,
    required: true,
  },
  metadata: {
    type: mongoose.Schema.Types.Mixed,
    default: {},
  },
  attempts: {
    type: Number,
    default: 0,
  },
  providerMessageId: {
    type: String,
    default: null,
  },
  consumedAt: {
    type: Date,
    default: null,
  },
  expiresAt: {
    type: Date,
    required: true,
    index: { expires: 0 },
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

module.exports = mongoose.model('PhoneOtp', PhoneOtpSchema);
