import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class BloodPressureReading {
  final int systolic;
  final int diastolic;
  final DateTime when;

  BloodPressureReading({required this.systolic, required this.diastolic, DateTime? when})
      : when = when ?? DateTime.now();
}

class BloodPressureProvider extends ChangeNotifier {
  final List<BloodPressureReading> _readings = [];

  List<BloodPressureReading> get readings => List.unmodifiable(_readings);

  void add(int sys, int dia, [DateTime? when]) {
    _readings.insert(0, BloodPressureReading(systolic: sys, diastolic: dia, when: when));
    notifyListeners();

    // Alert if outside normal range: systolic 115-125, diastolic 75-85
    final bool sysHigh = sys > 125;
    final bool sysLow = sys < 115;
    final bool diaHigh = dia > 85;
    final bool diaLow = dia < 75;

    if (sysHigh || diaHigh) {
      // Fire an immediate health alert
      try {
        NotificationService().showAlertNotification(title: 'Blood Pressure Alert', body: 'Your blood pressure is too high');
      } catch (_) {}
    } else if (sysLow || diaLow) {
      try {
        NotificationService().showAlertNotification(title: 'Blood Pressure Alert', body: 'Your blood pressure is too low');
      } catch (_) {}
    }
  }

  void remove(int index) {
    if (index >= 0 && index < _readings.length) {
      _readings.removeAt(index);
      notifyListeners();
    }
  }

  void update(int index, int systolic, int diastolic) {
    if (index >= 0 && index < _readings.length) {
      _readings[index] = BloodPressureReading(systolic: systolic, diastolic: diastolic, when: _readings[index].when);
      notifyListeners();
    }
  }

  double averageSystolic() => _readings.isEmpty ? 0 : _readings.map((r) => r.systolic).reduce((a, b) => a + b) / _readings.length;
  double averageDiastolic() => _readings.isEmpty ? 0 : _readings.map((r) => r.diastolic).reduce((a, b) => a + b) / _readings.length;
}