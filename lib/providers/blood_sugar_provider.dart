import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class BloodSugarReading {
  final int value;
  final DateTime when;

  BloodSugarReading({required this.value, DateTime? when}) : when = when ?? DateTime.now();
}

class BloodSugarProvider extends ChangeNotifier {
  final List<BloodSugarReading> _readings = [];

  List<BloodSugarReading> get readings => List.unmodifiable(_readings);

  void add(int value, {int? targetBloodSugar, DateTime? when}) {
    _readings.insert(0, BloodSugarReading(value: value, when: when));
    notifyListeners();
    
    // Use custom target if provided, otherwise use default value
    final target = targetBloodSugar ?? 100;
    
    // Alert if ±2 from target
    final bool tooHigh = value > target + 2;
    final bool tooLow = value < target - 2;
    
    if (tooHigh) {
      try {
        NotificationService().showAlertNotification(
          title: 'تنبيه سكر الدم',
          body: 'سكر دمك أعلى من الهدف المحدد ($target mg/dL)',
        );
      } catch (_) {}
    } else if (tooLow) {
      try {
        NotificationService().showAlertNotification(
          title: 'تنبيه سكر الدم',
          body: 'سكر دمك أقل من الهدف المحدد ($target mg/dL)',
        );
      } catch (_) {}
    }
  }

  void remove(int index) {
    if (index >= 0 && index < _readings.length) {
      _readings.removeAt(index);
      notifyListeners();
    }
  }

  void update(int index, int value) {
    if (index >= 0 && index < _readings.length) {
      _readings[index] = BloodSugarReading(value: value, when: _readings[index].when);
      notifyListeners();
    }
  }

  double average() => _readings.isEmpty ? 0 : _readings.map((r) => r.value).reduce((a, b) => a + b) / _readings.length;
}