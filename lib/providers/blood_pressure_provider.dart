import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/notification_service.dart';
import '../services/patient_data_sync_service.dart';

class BloodPressureReading {
  final int systolic;
  final int diastolic;
  final DateTime when;

  BloodPressureReading({required this.systolic, required this.diastolic, DateTime? when})
      : when = when ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'systolic': systolic,
        'diastolic': diastolic,
        'when': when.toIso8601String(),
      };

  factory BloodPressureReading.fromJson(Map<String, dynamic> json) {
    return BloodPressureReading(
      systolic: (json['systolic'] as num?)?.toInt() ?? 0,
      diastolic: (json['diastolic'] as num?)?.toInt() ?? 0,
      when: DateTime.tryParse(json['when']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class BloodPressureProvider extends ChangeNotifier {
  static const String _storageKey = 'blood_pressure_readings_v1';
  final List<BloodPressureReading> _readings = [];

  void _syncCloudInBackground() {
    unawaited(
      PatientDataSyncService()
          .syncLocalToCloudIfAuthenticated()
          .catchError((e) {
            debugPrint('[BloodPressureProvider] Background sync failed: $e');
          }),
    );
  }

  List<BloodPressureReading> get readings => List.unmodifiable(_readings);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    if (raw == null || raw.isEmpty) {
      _readings.clear();
      notifyListeners();
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        _readings
          ..clear()
          ..addAll(
            decoded
                .whereType<Map>()
                .map((item) => BloodPressureReading.fromJson(Map<String, dynamic>.from(item))),
          );
      }
    } catch (e) {
      debugPrint('[BloodPressureProvider.load] Failed to parse readings: $e');
      _readings.clear();
    }

    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = _readings.map((r) => r.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(payload));
    _syncCloudInBackground();
  }

  void add(int sys, int dia, {int? targetSystolic, int? targetDiastolic, DateTime? when}) async {
    _readings.insert(0, BloodPressureReading(systolic: sys, diastolic: dia, when: when));
    await _saveToPrefs();
    notifyListeners();

    // Use custom targets if provided, otherwise use default values
    final targetSys = targetSystolic ?? 120;
    final targetDia = targetDiastolic ?? 80;
    
    // Alert when reading reaches or exceeds ±2 from target.
    final bool sysHigh = sys >= targetSys + 2;
    final bool sysLow = sys <= targetSys - 2;
    final bool diaHigh = dia >= targetDia + 2;
    final bool diaLow = dia <= targetDia - 2;

    if (sysHigh || diaHigh) {
      // Fire an immediate health alert
      try {
        await NotificationService().showAlertNotification(
          title: 'تنبيه ضغط الدم', 
          body: 'ضغط دمك أعلى من الهدف المحدد ($targetSys/$targetDia)',
        );
      } catch (_) {}
    } else if (sysLow || diaLow) {
      try {
        await NotificationService().showAlertNotification(
          title: 'تنبيه ضغط الدم', 
          body: 'ضغط دمك أقل من الهدف المحدد ($targetSys/$targetDia)',
        );
      } catch (_) {}
    }
  }

  void remove(int index) async {
    if (index >= 0 && index < _readings.length) {
      _readings.removeAt(index);
      await _saveToPrefs();
      notifyListeners();
    }
  }

  void update(int index, int systolic, int diastolic) async {
    if (index >= 0 && index < _readings.length) {
      _readings[index] = BloodPressureReading(systolic: systolic, diastolic: diastolic, when: _readings[index].when);
      await _saveToPrefs();
      notifyListeners();
    }
  }

  double averageSystolic() => _readings.isEmpty ? 0 : _readings.map((r) => r.systolic).reduce((a, b) => a + b) / _readings.length;
  double averageDiastolic() => _readings.isEmpty ? 0 : _readings.map((r) => r.diastolic).reduce((a, b) => a + b) / _readings.length;
}