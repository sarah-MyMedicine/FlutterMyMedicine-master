import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/adherence_provider.dart';
import '../providers/appointment_provider.dart';
import '../providers/blood_pressure_provider.dart';
import '../providers/blood_sugar_provider.dart';
import '../providers/medication_provider.dart';
import '../providers/settings_provider.dart';
import 'api_service.dart';
import 'notification_service.dart';

class PatientDataSyncService {
  PatientDataSyncService._privateConstructor();
  static final PatientDataSyncService _instance =
      PatientDataSyncService._privateConstructor();
  factory PatientDataSyncService() => _instance;

  static const String _ownerKey = 'patient_data_owner_username';
  static const String _snapshotPrefix = 'patient_data_snapshot_';

  static const List<String> _stringKeys = [
    'medications_v1',
    'missed_doses_tracking',
    'blood_pressure_readings_v1',
    'blood_sugar_readings_v1',
    'adherence_records',
    'lab_results',
    'settings_name',
    'settings_gender',
    'settings_vibration',
    'settings_language',
  ];

  static const List<String> _stringListKeys = [
    'appointments',
    'settings_chronic_diseases',
  ];

  static const List<String> _intKeys = [
    'settings_age',
    'settings_theme_color',
    'settings_target_systolic',
    'settings_target_diastolic',
    'settings_target_blood_sugar',
  ];

  static const List<String> _boolKeys = [
    'settings_drug_knowledge',
  ];

  bool _isMeaningfulData(Map<String, dynamic> snapshot) {
    for (final value in snapshot.values) {
      if (value is String && value.isNotEmpty) return true;
      if (value is List && value.isNotEmpty) return true;
      if (value is num) return true;
      if (value is bool) return true;
      if (value is Map && value.isNotEmpty) return true;
    }
    return false;
  }

  Map<String, dynamic> _collectSnapshot(SharedPreferences prefs) {
    final snapshot = <String, dynamic>{};

    for (final key in _stringKeys) {
      final value = prefs.getString(key);
      if (value != null) snapshot[key] = value;
    }

    for (final key in _stringListKeys) {
      final value = prefs.getStringList(key);
      if (value != null) snapshot[key] = value;
    }

    for (final key in _intKeys) {
      final value = prefs.getInt(key);
      if (value != null) snapshot[key] = value;
    }

    for (final key in _boolKeys) {
      final value = prefs.getBool(key);
      if (value != null) snapshot[key] = value;
    }

    return snapshot;
  }

  Future<void> _applySnapshot(
    SharedPreferences prefs,
    Map<String, dynamic> snapshot,
  ) async {
    for (final key in _stringKeys) {
      if (snapshot.containsKey(key)) {
        final value = snapshot[key];
        if (value is String) {
          await prefs.setString(key, value);
        } else {
          await prefs.remove(key);
        }
      } else {
        await prefs.remove(key);
      }
    }

    for (final key in _stringListKeys) {
      if (snapshot.containsKey(key)) {
        final value = snapshot[key];
        if (value is List) {
          final asStrings = value.map((e) => e.toString()).toList();
          await prefs.setStringList(key, asStrings);
        } else {
          await prefs.remove(key);
        }
      } else {
        await prefs.remove(key);
      }
    }

    for (final key in _intKeys) {
      if (snapshot.containsKey(key)) {
        final value = snapshot[key];
        if (value is int) {
          await prefs.setInt(key, value);
        } else if (value is num) {
          await prefs.setInt(key, value.toInt());
        } else {
          await prefs.remove(key);
        }
      } else {
        await prefs.remove(key);
      }
    }

    for (final key in _boolKeys) {
      if (snapshot.containsKey(key)) {
        final value = snapshot[key];
        if (value is bool) {
          await prefs.setBool(key, value);
        } else {
          await prefs.remove(key);
        }
      } else {
        await prefs.remove(key);
      }
    }
  }

  Future<void> _clearTrackedLocalData(SharedPreferences prefs) async {
    for (final key in _stringKeys) {
      await prefs.remove(key);
    }
    for (final key in _stringListKeys) {
      await prefs.remove(key);
    }
    for (final key in _intKeys) {
      await prefs.remove(key);
    }
    for (final key in _boolKeys) {
      await prefs.remove(key);
    }
  }

  Future<void> _reloadProviders(BuildContext context) async {
    Future<void> safeLoad(String label, Future<void> Function() loader) async {
      try {
        await loader();
      } catch (e) {
        debugPrint('[PatientDataSync] Failed to reload $label: $e');
      }
    }

    await safeLoad('MedicationProvider', () => context.read<MedicationProvider>().load());
    await safeLoad('BloodPressureProvider', () => context.read<BloodPressureProvider>().load());
    await safeLoad('BloodSugarProvider', () => context.read<BloodSugarProvider>().load());
    await safeLoad('AppointmentProvider', () => context.read<AppointmentProvider>().load());
    await safeLoad('AdherenceProvider', () => context.read<AdherenceProvider>().load());
    await safeLoad('SettingsProvider', () => context.read<SettingsProvider>().load());
  }

  String _snapshotKeyForUser(String username) =>
      '$_snapshotPrefix${username.toLowerCase()}';

  Future<void> _cacheSnapshotForUser({
    required SharedPreferences prefs,
    required String username,
    required Map<String, dynamic> snapshot,
  }) async {
    await prefs.setString(
      _snapshotKeyForUser(username),
      jsonEncode(snapshot),
    );
  }

  Map<String, dynamic> _readCachedSnapshotForUser({
    required SharedPreferences prefs,
    required String username,
  }) {
    final raw = prefs.getString(_snapshotKeyForUser(username));
    if (raw == null || raw.isEmpty) return <String, dynamic>{};

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}

    return <String, dynamic>{};
  }

  Future<void> reloadProvidersFromLocal(BuildContext context) async {
    await _reloadProviders(context);
  }

  Future<void> clearLocalDataForLogout({
    required String? username,
    BuildContext? context,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final currentSnapshot = _collectSnapshot(prefs);
    final normalizedUsername = username?.trim().toLowerCase();

    if (normalizedUsername != null && normalizedUsername.isNotEmpty) {
      await _cacheSnapshotForUser(
        prefs: prefs,
        username: normalizedUsername,
        snapshot: currentSnapshot,
      );
    }

    await _clearTrackedLocalData(prefs);
    await prefs.remove(_ownerKey);
    await NotificationService().resetTrackedMedicationSchedules();

    if (context != null) {
      await _reloadProviders(context);
    }
  }

  Future<void> syncAfterAuthentication({
    required BuildContext context,
    required String username,
  }) async {
    if (!ApiService().isAuthenticated()) return;

    final prefs = await SharedPreferences.getInstance();
    final normalizedUsername = username.toLowerCase();
    final owner = prefs.getString(_ownerKey);
    final localSnapshot = _collectSnapshot(prefs);
    final cachedSnapshot = _readCachedSnapshotForUser(
      prefs: prefs,
      username: normalizedUsername,
    );

    try {
      final cloudSnapshot = await ApiService().getPatientDataSnapshot();
      final hasCloudData = _isMeaningfulData(cloudSnapshot);

      if (hasCloudData) {
        await _applySnapshot(prefs, cloudSnapshot);
        await prefs.setString(_ownerKey, normalizedUsername);
        await _cacheSnapshotForUser(
          prefs: prefs,
          username: normalizedUsername,
          snapshot: cloudSnapshot,
        );
        await _reloadProviders(context);
        debugPrint('[PatientDataSync] Pulled cloud snapshot for $username');
        return;
      }

      final localBelongsToCurrentUser =
          owner == null || owner.toLowerCase() == normalizedUsername;

      if (localBelongsToCurrentUser && _isMeaningfulData(localSnapshot)) {
        await ApiService().savePatientDataSnapshot(localSnapshot);
        await prefs.setString(_ownerKey, normalizedUsername);
        await _cacheSnapshotForUser(
          prefs: prefs,
          username: normalizedUsername,
          snapshot: localSnapshot,
        );
        await _reloadProviders(context);
        debugPrint('[PatientDataSync] Seeded cloud snapshot from local data for $username');
      } else if (_isMeaningfulData(cachedSnapshot)) {
        await _applySnapshot(prefs, cachedSnapshot);
        await prefs.setString(_ownerKey, normalizedUsername);
        try {
          await ApiService().savePatientDataSnapshot(cachedSnapshot);
        } catch (_) {}
        await _reloadProviders(context);
        debugPrint('[PatientDataSync] Restored cached local snapshot for $username');
      } else {
        await _clearTrackedLocalData(prefs);
        await prefs.setString(_ownerKey, normalizedUsername);
        await _cacheSnapshotForUser(
          prefs: prefs,
          username: normalizedUsername,
          snapshot: <String, dynamic>{},
        );
        await ApiService().savePatientDataSnapshot(<String, dynamic>{});
        await _reloadProviders(context);
        debugPrint('[PatientDataSync] Cleared stale local data and initialized empty cloud snapshot for $username');
      }
    } catch (e) {
      debugPrint('[PatientDataSync] syncAfterAuthentication error: $e');
      if (_isMeaningfulData(cachedSnapshot)) {
        await _applySnapshot(prefs, cachedSnapshot);
      } else {
        await _clearTrackedLocalData(prefs);
      }
      await prefs.setString(_ownerKey, normalizedUsername);
      await _reloadProviders(context);
    }
  }

  Future<void> syncLocalToCloudIfAuthenticated() async {
    if (!ApiService().isAuthenticated()) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('username');
      if (username == null || username.isEmpty) return;

      final snapshot = _collectSnapshot(prefs);
      final normalizedUsername = username.toLowerCase();
      await _cacheSnapshotForUser(
        prefs: prefs,
        username: normalizedUsername,
        snapshot: snapshot,
      );
      await ApiService()
          .savePatientDataSnapshot(snapshot)
          .timeout(const Duration(seconds: 5));
      await prefs.setString(_ownerKey, normalizedUsername);
    } catch (e) {
      debugPrint('[PatientDataSync] syncLocalToCloudIfAuthenticated error: $e');
    }
  }
}
