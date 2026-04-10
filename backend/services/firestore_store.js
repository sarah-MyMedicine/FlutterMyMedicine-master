const { admin, initializeFirebaseAdmin } = require('./firebase_admin_service');

const COLLECTIONS = {
  users: 'users',
  invitations: 'linkInvitations',
  alerts: 'emergencyAlerts',
};

function getDb() {
  if (!initializeFirebaseAdmin()) {
    throw new Error('Firebase Admin is not configured');
  }

  return admin.firestore();
}

function normalizeValue(value) {
  if (value instanceof admin.firestore.Timestamp) {
    return value.toDate();
  }

  if (Array.isArray(value)) {
    return value.map(normalizeValue);
  }

  if (value && typeof value === 'object') {
    return Object.fromEntries(
      Object.entries(value).map(([key, nestedValue]) => [key, normalizeValue(nestedValue)]),
    );
  }

  return value;
}

function mapDoc(doc) {
  if (!doc.exists) return null;
  return {
    id: doc.id,
    ...normalizeValue(doc.data()),
  };
}

async function createUser(data) {
  const db = getDb();
  const now = new Date();
  const ref = db.collection(COLLECTIONS.users).doc();
  const payload = {
    caregiverId: null,
    patientIds: [],
    fcmToken: null,
    patientData: {},
    authProvider: 'local',
    firebaseUid: null,
    email: null,
    phoneNumber: null,
    ...data,
    createdAt: now,
    updatedAt: now,
  };
  await ref.set(payload);
  return { id: ref.id, ...payload };
}

async function updateUser(id, updates) {
  const db = getDb();
  const ref = db.collection(COLLECTIONS.users).doc(id);
  const payload = {
    ...updates,
    updatedAt: new Date(),
  };
  await ref.set(payload, { merge: true });
  const updated = await ref.get();
  return mapDoc(updated);
}

async function deleteUser(id) {
  const db = getDb();
  await db.collection(COLLECTIONS.users).doc(id).delete();
}

async function getUserById(id) {
  if (!id) return null;
  const db = getDb();
  const doc = await db.collection(COLLECTIONS.users).doc(id).get();
  return mapDoc(doc);
}

async function listUsers() {
  const db = getDb();
  const snapshot = await db.collection(COLLECTIONS.users).get();
  return snapshot.docs.map(mapDoc).filter(Boolean)
    .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
}

async function getUserByUsername(username) {
  if (!username) return null;
  const normalizedUsername = String(username).trim().toLowerCase();
  const users = await listUsers();
  return users.find((user) => user.username === normalizedUsername) || null;
}

async function getUserByEmail(email) {
  if (!email) return null;
  const normalizedEmail = String(email).trim().toLowerCase();
  const users = await listUsers();
  return users.find((user) => user.email === normalizedEmail) || null;
}

async function getUserByFirebaseUid(firebaseUid) {
  if (!firebaseUid) return null;
  const users = await listUsers();
  return users.find((user) => user.firebaseUid === firebaseUid) || null;
}

async function getUserByPhoneNumber(phoneNumber) {
  if (!phoneNumber) return null;
  const users = await listUsers();
  return users.find((user) => user.phoneNumber === phoneNumber) || null;
}

async function searchUsers(query) {
  const normalizedQuery = String(query || '').trim().toLowerCase();
  if (!normalizedQuery) return [];
  const users = await listUsers();
  return users.filter((user) => {
    return user.username?.includes(normalizedQuery) ||
      user.email?.includes(normalizedQuery) ||
      user.name?.toLowerCase().includes(normalizedQuery);
  });
}

async function createInvitation(data) {
  const db = getDb();
  const now = new Date();
  const ref = db.collection(COLLECTIONS.invitations).doc();
  const payload = {
    status: 'pending',
    createdAt: now,
    expiresAt: new Date(now.getTime() + 24 * 60 * 60 * 1000),
    ...data,
  };
  await ref.set(payload);
  return { id: ref.id, ...payload };
}

async function listInvitations() {
  const db = getDb();
  const snapshot = await db.collection(COLLECTIONS.invitations).get();
  return snapshot.docs.map(mapDoc).filter(Boolean)
    .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
}

async function getInvitationByCode(invitationCode) {
  const normalized = String(invitationCode || '').trim().toUpperCase();
  if (!normalized) return null;
  const invitations = await listInvitations();
  return invitations.find((invitation) => invitation.invitationCode === normalized) || null;
}

async function updateInvitation(id, updates) {
  const db = getDb();
  const ref = db.collection(COLLECTIONS.invitations).doc(id);
  await ref.set(updates, { merge: true });
  return mapDoc(await ref.get());
}

async function deleteInvitationsForPatient(patientId) {
  const db = getDb();
  const invitations = await listInvitations();
  const matches = invitations.filter((invitation) => invitation.patientId === patientId);
  await Promise.all(matches.map((invitation) => db.collection(COLLECTIONS.invitations).doc(invitation.id).delete()));
}

async function createAlert(data) {
  const db = getDb();
  const now = new Date();
  const ref = db.collection(COLLECTIONS.alerts).doc();
  const payload = {
    status: 'unread',
    createdAt: now,
    ...data,
  };
  await ref.set(payload);
  return { id: ref.id, ...payload };
}

async function listAlertsByCaregiverId(caregiverId) {
  const db = getDb();
  const snapshot = await db.collection(COLLECTIONS.alerts).get();
  return snapshot.docs.map(mapDoc).filter(Boolean)
    .filter((alert) => alert.caregiverId === caregiverId)
    .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
}

async function getAlertById(id) {
  const db = getDb();
  return mapDoc(await db.collection(COLLECTIONS.alerts).doc(id).get());
}

async function updateAlert(id, updates) {
  const db = getDb();
  const ref = db.collection(COLLECTIONS.alerts).doc(id);
  await ref.set(updates, { merge: true });
  return mapDoc(await ref.get());
}

module.exports = {
  createUser,
  updateUser,
  deleteUser,
  getUserById,
  getUserByUsername,
  getUserByEmail,
  getUserByFirebaseUid,
  getUserByPhoneNumber,
  listUsers,
  searchUsers,
  createInvitation,
  listInvitations,
  getInvitationByCode,
  updateInvitation,
  deleteInvitationsForPatient,
  createAlert,
  listAlertsByCaregiverId,
  getAlertById,
  updateAlert,
};
