const admin = require('firebase-admin');

let initialized = false;

function initializeFirebaseAdmin() {
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
      console.log('[FirebaseAdmin] Initialized from FIREBASE_SERVICE_ACCOUNT_JSON');
      return true;
    }

    if (serviceAccountPath) {
      // eslint-disable-next-line global-require, import/no-dynamic-require
      const credentials = require(serviceAccountPath);
      admin.initializeApp({
        credential: admin.credential.cert(credentials),
      });
      initialized = true;
      console.log('[FirebaseAdmin] Initialized from FIREBASE_SERVICE_ACCOUNT_PATH');
      return true;
    }

    console.warn('[FirebaseAdmin] Not configured. Set FIREBASE_SERVICE_ACCOUNT_JSON or FIREBASE_SERVICE_ACCOUNT_PATH.');
    return false;
  } catch (error) {
    console.error('[FirebaseAdmin] Initialization failed:', error.message || error);
    return false;
  }
}

async function createCustomAuthToken({ uid, claims = {} }) {
  if (!uid) {
    throw new Error('uid is required to create a Firebase custom token');
  }

  if (!initializeFirebaseAdmin()) {
    throw new Error('Firebase Admin is not configured');
  }

  return admin.auth().createCustomToken(uid, claims);
}

module.exports = {
  admin,
  initializeFirebaseAdmin,
  createCustomAuthToken,
};
