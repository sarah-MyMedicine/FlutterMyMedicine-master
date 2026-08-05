const { admin, initializeFirebaseAdmin } = require('./firebase_admin_service');

async function sendPushNotification({
  token,
  title,
  body,
  data = {},
  channelId = 'caregiver_alerts',
  includeNotificationPayload = true,
}) {
  if (!token) {
    return { delivered: false, reason: 'missing-token' };
  }

  if (!initializeFirebaseAdmin()) {
    return { delivered: false, reason: 'not-configured' };
  }

  const normalizedData = Object.entries({
    ...data,
    title,
    body,
    channelId,
  }).reduce((acc, [key, value]) => {
      acc[key] = value == null ? '' : String(value);
      return acc;
    }, {});

  const message = {
    token,
    ...(includeNotificationPayload
        ? {
            notification: {
              title,
              body,
            },
          }
        : {}),
    data: normalizedData,
    android: {
      priority: 'high',
      ...(includeNotificationPayload
          ? {
              notification: {
                channelId,
                sound: 'default',
              },
            }
          : {}),
    },
    apns: {
      headers: {
        'apns-priority': '10',
        'apns-push-type': includeNotificationPayload ? 'alert' : 'background',
      },
      payload: {
        aps: {
          contentAvailable: true,
          ...(includeNotificationPayload
              ? {
                  alert: {
                    title,
                    body,
                  },
                  sound: 'default',
                  'interruption-level': 'time-sensitive',
                  mutableContent: true,
                }
              : {}),
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
