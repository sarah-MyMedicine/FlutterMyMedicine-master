const { admin, initializeFirebaseAdmin } = require('./firebase_admin_service');

async function sendPushNotification({ token, title, body, data = {}, channelId = 'caregiver_alerts' }) {
  if (!token) {
    return { delivered: false, reason: 'missing-token' };
  }

  if (!initializeFirebaseAdmin()) {
    return { delivered: false, reason: 'not-configured' };
  }

  const message = {
    token,
    notification: {
      title,
      body,
    },
    data: Object.entries(data).reduce((acc, [key, value]) => {
      acc[key] = value == null ? '' : String(value);
      return acc;
    }, {}),
    android: {
      priority: 'high',
      notification: {
        channelId,
        sound: 'default',
      },
    },
    apns: {
      headers: {
        'apns-priority': '10',
      },
      payload: {
        aps: {
          sound: 'default',
          contentAvailable: true,
        },
      },
    },
  };

  try {
    const messageId = await admin.messaging().send(message);
    return { delivered: true, messageId };
  } catch (error) {
    console.error('[Push] Failed to send push notification:', error.message || error);
    return { delivered: false, reason: error.message || 'send-failed' };
  }
}

module.exports = {
  sendPushNotification,
};
