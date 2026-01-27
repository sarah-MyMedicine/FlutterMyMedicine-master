import 'package:flutter/material.dart';

class BloodSugarReading {
  final int value;
  final DateTime when;

  BloodSugarReading({required this.value, DateTime? when}) : when = when ?? DateTime.now();
}

class BloodSugarProvider extends ChangeNotifier {
  final List<BloodSugarReading> _readings = [
    BloodSugarReading(value: 95, when: DateTime.now().subtract(const Duration(days: 0))),
    BloodSugarReading(value: 110, when: DateTime.now().subtract(const Duration(days: 1))),
  ];

  List<BloodSugarReading> get readings => List.unmodifiable(_readings);

  void add(int value, [DateTime? when]) {
    _readings.insert(0, BloodSugarReading(value: value, when: when));
    notifyListeners();
  }

  double average() => _readings.isEmpty ? 0 : _readings.map((r) => r.value).reduce((a, b) => a + b) / _readings.length;
}