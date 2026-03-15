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

  int _parseIntervalHours(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 24;
    return 24;
  }

  DateTime? _parseStartDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

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

  /// Calculate adherence score for a specific medication
  /// Returns percentage (0-100) based on doses taken vs expected
  double calculateMedicationAdherence({
    required String medicationName,
    required int intervalHours,
    DateTime? startDate,
    int daysToCheck = 30,
  }) {
    final now = DateTime.now();
    final checkFrom = now.subtract(Duration(days: daysToCheck));
    
    // Use startDate if medication started recently
    final effectiveStartDate = startDate != null && startDate.isAfter(checkFrom)
        ? startDate
        : checkFrom;
    
    // Calculate expected doses
    final hoursSinceStart = now.difference(effectiveStartDate).inHours;
    final expectedDoses = (hoursSinceStart / intervalHours).floor();
    
    if (expectedDoses <= 0) return 100.0; // New medication, no doses expected yet
    
    // Count actual doses taken
    final takenDoses = _logs.where((log) {
      return log.medicationName == medicationName &&
          log.taken &&
          log.when.isAfter(effectiveStartDate);
    }).length;
    
    // Calculate percentage, cap at 100%
    final score = (takenDoses / expectedDoses) * 100;
    return score > 100 ? 100.0 : score;
  }

  /// Calculate overall adherence score across all medications
  /// medications: List of maps with 'name', 'intervalHours', and optional 'startDate'
  double calculateOverallAdherence(List<Map<String, dynamic>> medications, {int daysToCheck = 30}) {
    if (medications.isEmpty) return 100.0;
    
    double totalScore = 0.0;
    int validMedications = 0;
    
    for (final med in medications) {
      final name = med['name']?.toString();
      final intervalValue = med['intervalHours'];
      final startDateValue = med['startDate'];
      
      if (name == null || name.isEmpty) continue;
      
      final intervalHours = _parseIntervalHours(intervalValue);
      final startDate = _parseStartDate(startDateValue);
      
      final score = calculateMedicationAdherence(
        medicationName: name,
        intervalHours: intervalHours,
        startDate: startDate,
        daysToCheck: daysToCheck,
      );
      
      totalScore += score;
      validMedications++;
    }
    
    return validMedications > 0 ? totalScore / validMedications : 100.0;
  }

  /// Get adherence data for all medications
  Map<String, double> getMedicationAdherenceScores(List<Map<String, dynamic>> medications, {int daysToCheck = 30}) {
    final scores = <String, double>{};
    
    for (final med in medications) {
      final name = med['name']?.toString();
      final intervalValue = med['intervalHours'];
      final startDateValue = med['startDate'];
      
      if (name == null || name.isEmpty) continue;
      
      final intervalHours = _parseIntervalHours(intervalValue);
      final startDate = _parseStartDate(startDateValue);
      
      scores[name] = calculateMedicationAdherence(
        medicationName: name,
        intervalHours: intervalHours,
        startDate: startDate,
        daysToCheck: daysToCheck,
      );
    }
    
    return scores;
  }
}
