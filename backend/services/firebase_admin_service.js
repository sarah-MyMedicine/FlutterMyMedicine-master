const admin = require('firebase-admin');
const { config } = require('../config/env');

let initialized = false;
const FIREBASE_AUTH_BASE_URL = 'https://identitytoolkit.googleapis.com/v1/accounts';

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

async function verifyFirebaseIdToken(idToken) {
  if (!idToken) {
    throw new Error('idToken is required');
  }

  if (!initializeFirebaseAdmin()) {
    throw new Error('Firebase Admin is not configured');
  }

  return admin.auth().verifyIdToken(idToken);
}

async function getFirebaseUserByEmail(email) {
  if (!email) return null;

  if (!initializeFirebaseAdmin()) {
    throw new Error('Firebase Admin is not configured');
  }

  try {
    return await admin.auth().getUserByEmail(email);
  } catch (error) {
    if (error.code === 'auth/user-not-found') {
      return null;
    }
    throw error;
  }
}

async function upsertEmailPasswordUser({ uid, email, password, displayName }) {
  if (!email || !password) {
    throw new Error('email and password are required');
  }

  if (!initializeFirebaseAdmin()) {
    throw new Error('Firebase Admin is not configured');
  }

  let userRecord = null;

  if (uid) {
    try {
      userRecord = await admin.auth().getUser(uid);
    } catch (error) {
      if (error.code !== 'auth/user-not-found') {
        throw error;
      }
    }
  }

  if (!userRecord) {
    userRecord = await getFirebaseUserByEmail(email);
  }

  if (userRecord) {
    const updates = {};

    if (userRecord.email !== email) {
      updates.email = email;
    }
    if (displayName && userRecord.displayName !== displayName) {
      updates.displayName = displayName;
    }
    if (password) {
      updates.password = password;
    }

    if (Object.keys(updates).length > 0) {
      userRecord = await admin.auth().updateUser(userRecord.uid, updates);
    }

    return userRecord;
  }

  return admin.auth().createUser({
    uid,
    email,
    password,
    displayName,
  });
}

function mapFirebaseIdentityError(code) {
  switch (code) {
    case 'EMAIL_NOT_FOUND':
    case 'INVALID_PASSWORD':
    case 'INVALID_LOGIN_CREDENTIALS':
      return 'Either the username/email or password is wrong. Please try again';
    case 'USER_DISABLED':
      return 'This account has been disabled';
    case 'TOO_MANY_ATTEMPTS_TRY_LATER':
      return 'Too many login attempts. Please try again later';
    default:
      return code || 'Firebase email/password authentication failed';
  }
}

async function signInWithEmailPassword({ email, password }) {
  if (!email || !password) {
    throw new Error('email and password are required');
  }

  if (!config.firebaseWebApiKey) {
    throw new Error('FIREBASE_WEB_API_KEY is not set');
  }

  const response = await fetch(
    `${FIREBASE_AUTH_BASE_URL}:signInWithPassword?key=${encodeURIComponent(config.firebaseWebApiKey)}`,
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        email,
        password,
        returnSecureToken: true,
      }),
    },
  );

  const data = await response.json().catch(() => ({}));
  if (!response.ok) {
    const code = data?.error?.message;
    throw new Error(mapFirebaseIdentityError(code));
  }

  return data;
}

function getFirestore() {
  if (!initializeFirebaseAdmin()) {
    throw new Error('Firebase Admin is not configured');
  }

  return admin.firestore();
}

module.exports = {
  admin,
  initializeFirebaseAdmin,
  createCustomAuthToken,
  verifyFirebaseIdToken,
  getFirebaseUserByEmail,
  upsertEmailPasswordUser,
  signInWithEmailPassword,
  getFirestore,
};
