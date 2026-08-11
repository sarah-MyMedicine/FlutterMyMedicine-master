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

  const isAlarmChannel =
    channelId === 'medication_monitor_alarm' ||
    channelId === 'sos_alarm' ||
    channelId === 'missed_dose_alarm';

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
                priority: isAlarmChannel ? 'max' : 'high',
                visibility: 'public',
                defaultSound: true,
                defaultVibrateTimings: true,
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

  const shouldRetry = (error) => {
    const code = String(error?.code || '').toLowerCase();
    return (
      code.includes('unavailable') ||
      code.includes('internal') ||
      code.includes('deadline-exceeded')
    );
  };

  const sendOnce = async () => admin.messaging().send(message);

  try {
    const messageId = await sendOnce();
    return { delivered: true, messageId };
  } catch (error) {
    if (shouldRetry(error)) {
      try {
        const retryMessageId = await sendOnce();
        return { delivered: true, messageId: retryMessageId, retried: true };
      } catch (retryError) {
        console.error('[Push] Retry failed:', retryError.message || retryError);
        return { delivered: false, reason: retryError.message || 'send-failed' };
      }
    }

    console.error('[Push] Failed to send push notification:', error.message || error);
    return { delivered: false, reason: error.message || 'send-failed' };
  }
}

module.exports = {
  sendPushNotification,
};
