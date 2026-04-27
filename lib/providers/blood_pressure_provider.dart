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
  static const int _dangerThreshold = 2;
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

    final targetSys = targetSystolic ?? 120;
    final targetDia = targetDiastolic ?? 80;
    await _notifyIfDangerous(
      systolic: sys,
      diastolic: dia,
      targetSystolic: targetSys,
      targetDiastolic: targetDia,
    );
  }

  void remove(int index) async {
    if (index >= 0 && index < _readings.length) {
      _readings.removeAt(index);
      await _saveToPrefs();
      notifyListeners();
    }
  }

  void update(
    int index,
    int systolic,
    int diastolic, {
    int? targetSystolic,
    int? targetDiastolic,
  }) async {
    if (index >= 0 && index < _readings.length) {
      _readings[index] = BloodPressureReading(systolic: systolic, diastolic: diastolic, when: _readings[index].when);
      await _saveToPrefs();
      notifyListeners();
      await _notifyIfDangerous(
        systolic: systolic,
        diastolic: diastolic,
        targetSystolic: targetSystolic ?? 120,
        targetDiastolic: targetDiastolic ?? 80,
      );
    }
  }

  Future<void> _notifyIfDangerous({
    required int systolic,
    required int diastolic,
    required int targetSystolic,
    required int targetDiastolic,
  }) async {
    final bool sysHigh = systolic - targetSystolic >= _dangerThreshold;
    final bool sysLow = targetSystolic - systolic >= _dangerThreshold;
    final bool diaHigh = diastolic - targetDiastolic >= _dangerThreshold;
    final bool diaLow = targetDiastolic - diastolic >= _dangerThreshold;

    if (sysHigh || diaHigh) {
      try {
        await NotificationService().showAlertNotification(
          title: 'تنبيه خطر: ضغط الدم',
          body: 'قراءة خطيرة: ضغط دمك أعلى من الهدف بـ $_dangerThreshold أو أكثر ($targetSystolic/$targetDiastolic).',
        );
      } catch (e) {
        debugPrint('[BloodPressureProvider] Failed to show high pressure alert: $e');
      }
    } else if (sysLow || diaLow) {
      try {
        await NotificationService().showAlertNotification(
          title: 'تنبيه خطر: ضغط الدم',
          body: 'قراءة خطيرة: ضغط دمك أقل من الهدف بـ $_dangerThreshold أو أكثر ($targetSystolic/$targetDiastolic).',
        );
      } catch (e) {
        debugPrint('[BloodPressureProvider] Failed to show low pressure alert: $e');
      }
    }
  }

  double averageSystolic() => _readings.isEmpty ? 0 : _readings.map((r) => r.systolic).reduce((a, b) => a + b) / _readings.length;
  double averageDiastolic() => _readings.isEmpty ? 0 : _readings.map((r) => r.diastolic).reduce((a, b) => a + b) / _readings.length;
}