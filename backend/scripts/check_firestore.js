const dotenv = require('dotenv');
const { getFirestore } = require('../services/firebase_admin_service');

dotenv.config();

async function main() {
  const db = getFirestore();
  const ref = db.collection('_healthchecks').doc('backend');
  const now = new Date();

  await ref.set(
    {
      checkedAt: now,
      source: 'backend/scripts/check_firestore.js',
    },
    { merge: true },
  );

  const snapshot = await ref.get();
  const data = snapshot.data() || {};

  console.log('[Firestore Check] Success');
  console.log(`[Firestore Check] Project document exists: ${snapshot.exists}`);
  console.log(`[Firestore Check] Last checked at: ${data.checkedAt}`);
}

main().catch((error) => {
  console.error('[Firestore Check] Failed:', error.message || error);
  process.exit(1);
});