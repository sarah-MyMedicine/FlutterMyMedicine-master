import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/notification_service.dart';
import '../services/patient_data_sync_service.dart';

class BloodSugarReading {
  final int value;
  final DateTime when;

  BloodSugarReading({required this.value, DateTime? when}) : when = when ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'value': value,
        'when': when.toIso8601String(),
      };

  factory BloodSugarReading.fromJson(Map<String, dynamic> json) {
    return BloodSugarReading(
      value: (json['value'] as num?)?.toInt() ?? 0,
      when: DateTime.tryParse(json['when']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class BloodSugarProvider extends ChangeNotifier {
  static const String _storageKey = 'blood_sugar_readings_v1';
  static const int _dangerThreshold = 2;
  final List<BloodSugarReading> _readings = [];

  void _syncCloudInBackground() {
    unawaited(
      PatientDataSyncService()
          .syncLocalToCloudIfAuthenticated()
          .catchError((e) {
            debugPrint('[BloodSugarProvider] Background sync failed: $e');
          }),
    );
  }

  List<BloodSugarReading> get readings => List.unmodifiable(_readings);

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
                .map((item) => BloodSugarReading.fromJson(Map<String, dynamic>.from(item))),
          );
      }
    } catch (e) {
      debugPrint('[BloodSugarProvider.load] Failed to parse readings: $e');
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

  void add(int value, {int? targetBloodSugar, DateTime? when}) async {
    _readings.insert(0, BloodSugarReading(value: value, when: when));
    await _saveToPrefs();
    notifyListeners();

    final target = targetBloodSugar ?? 100;
    await _notifyIfDangerous(value: value, target: target);
  }

  void remove(int index) async {
    if (index >= 0 && index < _readings.length) {
      _readings.removeAt(index);
      await _saveToPrefs();
      notifyListeners();
    }
  }

  void update(int index, int value, {int? targetBloodSugar}) async {
    if (index >= 0 && index < _readings.length) {
      _readings[index] = BloodSugarReading(value: value, when: _readings[index].when);
      await _saveToPrefs();
      notifyListeners();
      await _notifyIfDangerous(value: value, target: targetBloodSugar ?? 100);
    }
  }

  Future<void> _notifyIfDangerous({required int value, required int target}) async {
    final bool tooHigh = value - target >= _dangerThreshold;
    final bool tooLow = target - value >= _dangerThreshold;

    if (tooHigh) {
      try {
        await NotificationService().showAlertNotification(
          title: 'تنبيه خطر: سكر الدم',
          body: 'قراءة خطيرة: سكر الدم أعلى من الهدف بـ $_dangerThreshold أو أكثر ($target mg/dL).',
        );
      } catch (e) {
        debugPrint('[BloodSugarProvider] Failed to show high sugar alert: $e');
      }
    } else if (tooLow) {
      try {
        await NotificationService().showAlertNotification(
          title: 'تنبيه خطر: سكر الدم',
          body: 'قراءة خطيرة: سكر الدم أقل من الهدف بـ $_dangerThreshold أو أكثر ($target mg/dL).',
        );
      } catch (e) {
        debugPrint('[BloodSugarProvider] Failed to show low sugar alert: $e');
      }
    }
  }

  double average() => _readings.isEmpty ? 0 : _readings.map((r) => r.value).reduce((a, b) => a + b) / _readings.length;
}