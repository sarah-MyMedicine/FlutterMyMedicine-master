import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AdherenceLog {
  final String medicationName;
  final String dose;
  final DateTime when;
  final bool taken;

  AdherenceLog({
    required this.medicationName,
    required this.dose,
    required this.when,
    this.taken = true,
  });

  Map<String, dynamic> toJson() => {
        'medicationName': medicationName,
        'dose': dose,
        'timestamp': when.toIso8601String(),
        'taken': taken,
      };

  factory AdherenceLog.fromJson(Map<String, dynamic> json) => AdherenceLog(
        medicationName: json['medicationName'] ?? '',
        dose: json['dose'] ?? '',
        when: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
        taken: json['taken'] ?? true,
      );
}

class AdherenceProvider extends ChangeNotifier {
  List<AdherenceLog> _logs = [];

  List<AdherenceLog> get logs {
    // Return logs sorted by date descending
    return List.from(_logs)..sort((a, b) => b.when.compareTo(a.when));
  }

  List<Map<String, dynamic>> get records {
    // Return only records from the past 30 days for backward compatibility
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    return _logs
        .where((log) => log.when.isAfter(cutoff))
        .map((log) => {
              'medicationName': log.medicationName,
              'dose': log.dose,
              'timestamp': log.when.toIso8601String(),
            })
        .toList();
  }

  AdherenceProvider() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('adherence_records');
    if (raw != null) {
      try {
        final List<dynamic> decoded = jsonDecode(raw);
        _logs = decoded.map((e) => AdherenceLog.fromJson(Map<String, dynamic>.from(e))).toList();
        notifyListeners();
      } catch (_) {}
    }
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('adherence_records', jsonEncode(_logs.map((log) => log.toJson()).toList()));
  }

  /// Record that a medication was taken
  Future<void> recordTaken({
    required String medicationName,
    required String dose,
    DateTime? takenAt,
  }) async {
    final timestamp = takenAt ?? DateTime.now();
    _logs.add(AdherenceLog(
      medicationName: medicationName,
      dose: dose,
      when: timestamp,
      taken: true,
    ));
    await _saveToPrefs();
    notifyListeners();
  }

  /// Clear all adherence records (optional utility)
  Future<void> clearAll() async {
    _logs.clear();
    await _saveToPrefs();
    notifyListeners();
  }
}
