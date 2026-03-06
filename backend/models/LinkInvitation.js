const mongoose = require('mongoose');

const LinkInvitationSchema = new mongoose.Schema({
  invitationCode: {
    type: String,
    required: true,
    unique: true,
    match: /^[A-Z0-9]{6}$/,
  },
  patientId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  patientUsername: {
    type: String,
    required: true,
  },
  patientName: {
    type: String,
    required: true,
  },
  status: {
    type: String,
    enum: ['pending', 'accepted', 'expired'],
    default: 'pending',
  },
  createdAt: {
    type: Date,
    default: Date.now,
    index: { expires: 86400 }, // Auto-delete after 24 hours
  },
  expiresAt: {
    type: Date,
    default: () => new Date(Date.now() + 24 * 60 * 60 * 1000), // 24 hours from now
    index: { expires: 0 }, // TTL index for auto-deletion
  },
});

module.exports = mongoose.model('LinkInvitation', LinkInvitationSchema);
