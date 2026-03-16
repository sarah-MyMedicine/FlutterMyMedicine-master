import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/patient_data_sync_service.dart';

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
    load();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('adherence_records');
    if (raw != null) {
      try {
        final List<dynamic> decoded = jsonDecode(raw);
        _logs = decoded.map((e) => AdherenceLog.fromJson(Map<String, dynamic>.from(e))).toList();
        notifyListeners();
      } catch (_) {}
      return;
    }

    _logs = [];
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('adherence_records', jsonEncode(_logs.map((log) => log.toJson()).toList()));
    await PatientDataSyncService().syncLocalToCloudIfAuthenticated();
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

  /// Calculate adherence score for a specific medication.
  /// Returns null until the first dose is recorded as taken.
  /// Expected doses are counted only from entry date (or fallback window)
  /// up to the present time (future expected doses are excluded).
  double? calculateMedicationAdherence({
    required String medicationName,
    required int intervalHours,
    DateTime? startDate,
    int daysToCheck = 30,
  }) {
    final now = DateTime.now();
    final checkFrom = now.subtract(Duration(days: daysToCheck));

    final effectiveStartDate = startDate ?? checkFrom;
    final safeIntervalHours = intervalHours <= 0 ? 24 : intervalHours;

    // Include taken records from effective start onward.
    // Future taken records are allowed by requirement.
    final takenLogs = _logs.where((log) {
      return log.medicationName == medicationName &&
          log.taken &&
          log.when.isAfter(effectiveStartDate);
    }).toList();

    // Do not calculate adherence before first taken portion is recorded.
    if (takenLogs.isEmpty) return null;

    // Expected portions are counted only up to now (never from the future).
    final expectedDoses = now.isAfter(effectiveStartDate)
        ? (now.difference(effectiveStartDate).inHours / safeIntervalHours).floor()
        : 0;

    if (expectedDoses <= 0) return 100.0;

    final takenDoses = takenLogs.length;

    // Calculate percentage, cap at 100%
    final score = (takenDoses / expectedDoses) * 100;
    return score > 100 ? 100.0 : score;
  }

  /// Calculate overall adherence score across all medications
  /// medications: List of maps with 'name', 'intervalHours', and optional 'startDate'
  double? calculateOverallAdherence(List<Map<String, dynamic>> medications, {int daysToCheck = 30}) {
    if (medications.isEmpty) return null;
    
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

      if (score == null) continue;

      totalScore += score;
      validMedications++;
    }

    return validMedications > 0 ? totalScore / validMedications : null;
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
      
      final score = calculateMedicationAdherence(
        medicationName: name,
        intervalHours: intervalHours,
        startDate: startDate,
        daysToCheck: daysToCheck,
      );

      if (score != null) {
        scores[name] = score;
      }
    }
    
    return scores;
  }
}
