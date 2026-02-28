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

  void add(int sys, int dia, {int? targetSystolic, int? targetDiastolic, DateTime? when}) {
    _readings.insert(0, BloodPressureReading(systolic: sys, diastolic: dia, when: when));
    notifyListeners();

    // Use custom targets if provided, otherwise use default values
    final targetSys = targetSystolic ?? 120;
    final targetDia = targetDiastolic ?? 80;
    
    // Alert if ±2 from target
    final bool sysHigh = sys > targetSys + 2;
    final bool sysLow = sys < targetSys - 2;
    final bool diaHigh = dia > targetDia + 2;
    final bool diaLow = dia < targetDia - 2;

    if (sysHigh || diaHigh) {
      // Fire an immediate health alert
      try {
        NotificationService().showAlertNotification(
          title: 'تنبيه ضغط الدم', 
          body: 'ضغط دمك أعلى من الهدف المحدد (${targetSys}/${targetDia})',
        );
      } catch (_) {}
    } else if (sysLow || diaLow) {
      try {
        NotificationService().showAlertNotification(
          title: 'تنبيه ضغط الدم', 
          body: 'ضغط دمك أقل من الهدف المحدد (${targetSys}/${targetDia})',
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

  void update(int index, int systolic, int diastolic) {
    if (index >= 0 && index < _readings.length) {
      _readings[index] = BloodPressureReading(systolic: systolic, diastolic: diastolic, when: _readings[index].when);
      notifyListeners();
    }
  }

  double averageSystolic() => _readings.isEmpty ? 0 : _readings.map((r) => r.systolic).reduce((a, b) => a + b) / _readings.length;
  double averageDiastolic() => _readings.isEmpty ? 0 : _readings.map((r) => r.diastolic).reduce((a, b) => a + b) / _readings.length;
}