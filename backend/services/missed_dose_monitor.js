const { config } = require('../config/env');
const store = require('./firestore_store');
const { sendPushNotification } = require('./push_service');

const BACKEND_STATE_KEY = 'backend_missed_dose_state';

let monitorTimer = null;
let isRunningCycle = false;

function normalizeMedicationEntry(entry) {
  if (!entry || typeof entry !== 'object') return null;
  const map = {};
  for (const [key, value] of Object.entries(entry)) {
    map[String(key)] = value == null ? null : String(value);
  }
  return map;
}

function parseMedications(patientData) {
  const raw = patientData?.medications_v1;
  if (!raw) return [];

  let decoded = raw;
  if (typeof raw === 'string') {
    try {
      decoded = JSON.parse(raw);
    } catch (_) {
      return [];
    }
  }

  if (!Array.isArray(decoded)) return [];
  return decoded.map(normalizeMedicationEntry).filter(Boolean);
}

function parsePositiveInt(value, fallback) {
  const parsed = Number.parseInt(String(value ?? ''), 10);
  if (!Number.isFinite(parsed) || parsed <= 0) return fallback;
  return parsed;
}

function calculateExpectedDoseTime(item, now) {
  const intervalHours = parsePositiveInt(item.intervalHours, 24);
  const lastTaken = item.lastTaken ? new Date(item.lastTaken) : null;

  if (lastTaken && !Number.isNaN(lastTaken.getTime())) {
    return {
      expectedDoseTime: new Date(lastTaken.getTime() + intervalHours * 60 * 60 * 1000),
      intervalHours,
    };
  }

  const startTime = (item.startTime || '').trim();
  if (!startTime) return null;

  const parts = startTime.split(':');
  if (parts.length !== 2) return null;
  const h = parsePositiveInt(parts[0], -1);
  const m = parsePositiveInt(parts[1], -1);
  if (h < 0 || h > 23 || m < 0 || m > 59) return null;

  let baseDate = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const startDate = (item.startDate || '').trim();
  if (startDate) {
    const parsedBase = new Date(startDate);
    if (!Number.isNaN(parsedBase.getTime())) {
      baseDate = new Date(parsedBase.getFullYear(), parsedBase.getMonth(), parsedBase.getDate());
    }
  }

  let expectedDoseTime = new Date(
    baseDate.getFullYear(),
    baseDate.getMonth(),
    baseDate.getDate(),
    h,
    m,
    0,
    0,
  );

  while (expectedDoseTime > now) {
    expectedDoseTime = new Date(expectedDoseTime.getTime() - intervalHours * 60 * 60 * 1000);
  }

  while (expectedDoseTime < new Date(now.getTime() - intervalHours * 2 * 60 * 60 * 1000)) {
    expectedDoseTime = new Date(expectedDoseTime.getTime() + intervalHours * 60 * 60 * 1000);
  }

  return { expectedDoseTime, intervalHours };
}

function computeMissedDoseCount(now, expectedDoseTime, intervalHours) {
  const elapsedHours = (now.getTime() - expectedDoseTime.getTime()) / (60 * 60 * 1000);
  return 1 + Math.floor(elapsedHours / intervalHours);
}

function buildMissedDoseMessage(patientName, dosesMissed, medicationName) {
  return `${patientName} missed ${dosesMissed} dose${dosesMissed === 1 ? '' : 's'} of ${medicationName}`;
}

function safeStateObject(raw) {
  if (!raw || typeof raw !== 'object' || Array.isArray(raw)) return {};
  return { ...raw };
}

async function processPatientMissedDoses(patient, now, graceHours) {
  if (!patient || patient.userType !== 'patient' || !patient.caregiverId) return;

  const caregiver = await store.getUserById(patient.caregiverId);
  if (!caregiver) return;

  const patientData = safeStateObject(patient.patientData);
  const medications = parseMedications(patientData);
  if (medications.length === 0) return;

  const graceMs = Math.max(0, graceHours) * 60 * 60 * 1000;
  const missedState = safeStateObject(patientData[BACKEND_STATE_KEY]);
  let stateChanged = false;

  for (const item of medications) {
    const prefix = (item.notifPrefix || '').trim();
    if (!prefix) continue;

    const medicationName = (item.name || 'Unknown Medication').trim() || 'Unknown Medication';
    const timing = calculateExpectedDoseTime(item, now);
    if (!timing) continue;

    const { expectedDoseTime, intervalHours } = timing;
    const missedThreshold = new Date(expectedDoseTime.getTime() + graceMs);
    const currentLastTaken = (item.lastTaken || '').trim();

    const entryRaw = safeStateObject(missedState[prefix]);
    const entry = {
      lastTaken: (entryRaw.lastTaken || '').toString(),
      lastNotifiedMissed: Number(entryRaw.lastNotifiedMissed) || 0,
      lastAlertAt: (entryRaw.lastAlertAt || '').toString(),
    };

    if (entry.lastTaken !== currentLastTaken) {
      entry.lastTaken = currentLastTaken;
      entry.lastNotifiedMissed = 0;
      stateChanged = true;
    }

    if (now > missedThreshold) {
      const dosesMissed = computeMissedDoseCount(now, expectedDoseTime, intervalHours);
      if (dosesMissed > entry.lastNotifiedMissed) {
        const alertMessage = buildMissedDoseMessage(
          patient.name || patient.username || 'Patient',
          dosesMissed,
          medicationName,
        );

        const alert = await store.createAlert({
          patientId: patient.id,
          caregiverId: caregiver.id,
          patientUsername: patient.username,
          patientName: patient.name,
          caregiverUsername: caregiver.username,
          caregiverName: caregiver.name,
          classification: 'missed_dose',
          message: alertMessage,
          medicationName,
          consecutiveMissed: dosesMissed,
          notifPrefix: prefix,
          source: 'backend_monitor',
        });

        let pushDelivered = false;
        if (caregiver.fcmToken) {
          const pushResult = await sendPushNotification({
            token: caregiver.fcmToken,
            title: `${patient.name || patient.username || 'Patient'} missed dose alert`,
            body: alertMessage,
            channelId: 'missed_dose_alarm',
            data: {
              type: 'missed_dose',
              alertId: alert.id,
              patientUsername: patient.username,
              patientName: patient.name,
              medicationName,
              consecutiveMissed: dosesMissed,
              notifPrefix: prefix,
            },
          });
          pushDelivered = pushResult.delivered;
        }

        entry.lastNotifiedMissed = dosesMissed;
        entry.lastAlertAt = new Date().toISOString();
        stateChanged = true;

        console.log(
          `[MissedDoseMonitor] Alert sent for patient=${patient.username} medication=${medicationName} missed=${dosesMissed} pushDelivered=${pushDelivered}`,
        );
      }
    } else if (entry.lastNotifiedMissed !== 0) {
      entry.lastNotifiedMissed = 0;
      stateChanged = true;
    }

    missedState[prefix] = entry;
  }

  if (stateChanged) {
    const nextData = {
      ...patientData,
      [BACKEND_STATE_KEY]: missedState,
    };
    await store.updateUser(patient.id, { patientData: nextData });
  }
}

async function runMissedDoseMonitorCycle() {
  if (isRunningCycle) return;
  isRunningCycle = true;

  try {
    const users = await store.listUsers();
    const patients = users.filter((user) => user && user.userType === 'patient' && user.caregiverId);
    const now = new Date();
    const graceHours = Math.max(0, Number(config.missedDoseGraceHours) || 1);

    for (const patient of patients) {
      await processPatientMissedDoses(patient, now, graceHours);
    }
  } catch (error) {
    console.error('[MissedDoseMonitor] Cycle failed:', error);
  } finally {
    isRunningCycle = false;
  }
}

function startMissedDoseMonitor() {
  if (monitorTimer) return;
  if (config.missedDoseMonitorEnabled === false) {
    console.log('[MissedDoseMonitor] Disabled by config');
    return;
  }

  const intervalMs = Math.max(15000, Number(config.missedDoseMonitorIntervalMs) || 60000);
  console.log(`[MissedDoseMonitor] Starting with interval=${intervalMs}ms`);

  monitorTimer = setInterval(() => {
    runMissedDoseMonitorCycle().catch((error) => {
      console.error('[MissedDoseMonitor] Unhandled cycle error:', error);
    });
  }, intervalMs);

  runMissedDoseMonitorCycle().catch((error) => {
    console.error('[MissedDoseMonitor] Initial cycle error:', error);
  });
}

function stopMissedDoseMonitor() {
  if (!monitorTimer) return;
  clearInterval(monitorTimer);
  monitorTimer = null;
}

module.exports = {
  startMissedDoseMonitor,
  stopMissedDoseMonitor,
  runMissedDoseMonitorCycle,
};
