const admin = require('firebase-admin');

let initialized = false;

function _initializeFirebaseAdmin() {
  if (initialized) return true;

  try {
    const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;
    const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;

    if (serviceAccountJson) {
      const credentials = JSON.parse(serviceAccountJson);
      admin.initializeApp({
        credential: admin.credential.cert(credentials),
      });
      initialized = true;
      console.log('[Push] Firebase Admin initialized from FIREBASE_SERVICE_ACCOUNT_JSON');
      return true;
    }

    if (serviceAccountPath) {
      // eslint-disable-next-line global-require, import/no-dynamic-require
      const credentials = require(serviceAccountPath);
      admin.initializeApp({
        credential: admin.credential.cert(credentials),
      });
      initialized = true;
      console.log('[Push] Firebase Admin initialized from FIREBASE_SERVICE_ACCOUNT_PATH');
      return true;
    }

    console.warn('[Push] Firebase Admin not configured. Set FIREBASE_SERVICE_ACCOUNT_JSON or FIREBASE_SERVICE_ACCOUNT_PATH.');
    return false;
  } catch (error) {
    console.error('[Push] Firebase Admin initialization failed:', error.message || error);
    return false;
  }
}

async function sendPushNotification({ token, title, body, data = {}, channelId = 'caregiver_alerts' }) {
  if (!token) {
    return { delivered: false, reason: 'missing-token' };
  }

  if (!_initializeFirebaseAdmin()) {
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
