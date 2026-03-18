import 'dart:async';

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

class MedicationRankTier {
  final String title;
  final int requiredDays;

  const MedicationRankTier({required this.title, required this.requiredDays});
}

class MedicationRankStatus {
  final int streakDays;
  final MedicationRankTier? currentTier;
  final MedicationRankTier? nextTier;

  const MedicationRankStatus({
    required this.streakDays,
    required this.currentTier,
    required this.nextTier,
  });

  bool get hasRank => currentTier != null;
  bool get isHighestRank => currentTier != null && nextTier == null;
}

class _ScheduledMedication {
  final String key;
  final int intervalHours;
  final DateTime firstOccurrence;

  const _ScheduledMedication({
    required this.key,
    required this.intervalHours,
    required this.firstOccurrence,
  });
}

class _ScheduledDoseResult {
  final DateTime scheduledAt;
  final bool taken;

  const _ScheduledDoseResult({required this.scheduledAt, required this.taken});
}

class AdherenceProvider extends ChangeNotifier {
  List<AdherenceLog> _logs = [];
  static const List<MedicationRankTier> _rankTiers = [
    MedicationRankTier(title: 'المعدّل', requiredDays: 3),
    MedicationRankTier(title: 'السبع', requiredDays: 7),
    MedicationRankTier(title: 'الذيب', requiredDays: 30),
    MedicationRankTier(title: 'الملك', requiredDays: 90),
  ];

  void _syncCloudInBackground() {
    unawaited(
      PatientDataSyncService()
          .syncLocalToCloudIfAuthenticated()
          .catchError((e) {
            debugPrint('[AdherenceProvider] Background sync failed: $e');
          }),
    );
  }

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

  String _medicationKey(String name, String dose) => '$name::$dose';

  DateTime? _resolveFirstOccurrence({
    required Map<String, dynamic> medication,
    required DateTime now,
    required DateTime windowStart,
  }) {
    final startTime = medication['startTime']?.toString();
    if (startTime == null || startTime.isEmpty) return null;

    final parts = startTime.split(':');
    if (parts.length != 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;

    final name = medication['name']?.toString().trim() ?? '';
    final dose = medication['dose']?.toString().trim() ?? '';
    final startDate = _parseStartDate(medication['startDate']);
    final relevantLogs = _logs
        .where(
          (log) =>
              log.taken &&
              log.medicationName == name &&
              (dose.isEmpty || log.dose == dose),
        )
        .toList()
      ..sort((a, b) => a.when.compareTo(b.when));

    final baseDate = startDate ??
        (relevantLogs.isNotEmpty ? relevantLogs.first.when : now);

    var firstOccurrence = DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      hour,
      minute,
    );

    final intervalHours = _parseIntervalHours(medication['intervalHours']);
    final safeIntervalHours = intervalHours <= 0 ? 24 : intervalHours;

    while (
        firstOccurrence.isBefore(windowStart.subtract(Duration(hours: safeIntervalHours)))) {
      firstOccurrence = firstOccurrence.add(Duration(hours: safeIntervalHours));
    }

    return firstOccurrence.isAfter(now) ? null : firstOccurrence;
  }

  List<_ScheduledMedication> _buildSchedules(
    List<Map<String, dynamic>> medications,
    DateTime windowStart,
    DateTime now,
  ) {
    final schedules = <_ScheduledMedication>[];

    for (final medication in medications) {
      final name = medication['name']?.toString().trim() ?? '';
      if (name.isEmpty) continue;

      final dose = medication['dose']?.toString().trim() ?? '';
      final intervalHours = _parseIntervalHours(medication['intervalHours']);
      final safeIntervalHours = intervalHours <= 0 ? 24 : intervalHours;
      final firstOccurrence = _resolveFirstOccurrence(
        medication: medication,
        now: now,
        windowStart: windowStart,
      );

      if (firstOccurrence == null) continue;

      schedules.add(
        _ScheduledMedication(
          key: _medicationKey(name, dose),
          intervalHours: safeIntervalHours,
          firstOccurrence: firstOccurrence,
        ),
      );
    }

    return schedules;
  }

  List<_ScheduledDoseResult> _buildScheduledDoseResults(
    List<_ScheduledMedication> schedules,
    DateTime windowStart,
    DateTime now,
  ) {
    final takenByMedication = <String, List<DateTime>>{};

    for (final log in _logs.where((entry) => entry.taken)) {
      final key = _medicationKey(log.medicationName, log.dose);
      final bucket = takenByMedication.putIfAbsent(key, () => <DateTime>[]);
      bucket.add(log.when);
    }

    for (final entry in takenByMedication.values) {
      entry.sort();
    }

    final results = <_ScheduledDoseResult>[];

    for (final schedule in schedules) {
      final takenLogs = takenByMedication[schedule.key] ?? const <DateTime>[];
      var logIndex = 0;
      var occurrence = schedule.firstOccurrence;

      while (occurrence.isBefore(windowStart)) {
        occurrence = occurrence.add(Duration(hours: schedule.intervalHours));
      }

      while (!occurrence.isAfter(now)) {
        final nextOccurrence = occurrence.add(
          Duration(hours: schedule.intervalHours),
        );
        final matchWindowStart = occurrence.subtract(const Duration(hours: 1));
        var matched = false;

        while (
            logIndex < takenLogs.length && takenLogs[logIndex].isBefore(matchWindowStart)) {
          logIndex++;
        }

        if (logIndex < takenLogs.length) {
          final candidate = takenLogs[logIndex];
          if (!candidate.isBefore(matchWindowStart) &&
              candidate.isBefore(nextOccurrence)) {
            matched = true;
            logIndex++;
          }
        }

        results.add(
          _ScheduledDoseResult(scheduledAt: occurrence, taken: matched),
        );
        occurrence = nextOccurrence;
      }
    }

    return results;
  }

  bool _hasPendingDoseLaterToday(_ScheduledMedication schedule, DateTime now) {
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    var occurrence = schedule.firstOccurrence;

    while (occurrence.isBefore(now)) {
      occurrence = occurrence.add(Duration(hours: schedule.intervalHours));
    }

    return occurrence.isAfter(now) && occurrence.isBefore(tomorrow);
  }

  int _calculatePerfectDayStreak(
    List<_ScheduledMedication> schedules,
    List<_ScheduledDoseResult> results,
    DateTime now,
  ) {
    if (schedules.isEmpty) return 0;

    final dosesByDay = <DateTime, List<_ScheduledDoseResult>>{};
    for (final result in results) {
      final dayKey = DateTime(
        result.scheduledAt.year,
        result.scheduledAt.month,
        result.scheduledAt.day,
      );
      dosesByDay.putIfAbsent(dayKey, () => <_ScheduledDoseResult>[]).add(result);
    }

    var streak = 0;
    final today = DateTime(now.year, now.month, now.day);

    for (var offset = 0; offset < _rankTiers.last.requiredDays; offset++) {
      final dayStart = today.subtract(Duration(days: offset));
      final dayEnd = offset == 0 ? now : dayStart.add(const Duration(days: 1));

      if (offset == 0 &&
          schedules.any((schedule) => _hasPendingDoseLaterToday(schedule, now))) {
        continue;
      }

      final hasActiveMedication = schedules.any(
        (schedule) => !schedule.firstOccurrence.isAfter(dayEnd),
      );

      if (!hasActiveMedication) {
        if (streak == 0) {
          continue;
        }
        break;
      }

      final dayResults = dosesByDay[dayStart] ?? const <_ScheduledDoseResult>[];
      final missedAny = dayResults.any((result) => !result.taken);
      if (missedAny) {
        break;
      }

      streak++;
    }

    return streak;
  }

  MedicationRankStatus calculateRankStatus(
    List<Map<String, dynamic>> medications,
  ) {
    final now = DateTime.now();
    final windowStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: _rankTiers.last.requiredDays - 1));

    final schedules = _buildSchedules(medications, windowStart, now);
    if (schedules.isEmpty) {
      return MedicationRankStatus(
        streakDays: 0,
        currentTier: null,
        nextTier: _rankTiers.first,
      );
    }

    final results = _buildScheduledDoseResults(schedules, windowStart, now);
    final streakDays = _calculatePerfectDayStreak(schedules, results, now);

    MedicationRankTier? currentTier;
    MedicationRankTier? nextTier;

    for (final tier in _rankTiers) {
      if (streakDays >= tier.requiredDays) {
        currentTier = tier;
      } else {
        nextTier = tier;
        break;
      }
    }

    return MedicationRankStatus(
      streakDays: streakDays,
      currentTier: currentTier,
      nextTier: nextTier,
    );
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
    _syncCloudInBackground();
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
    String? dose,
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
          (dose == null || dose.isEmpty || log.dose == dose) &&
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
        dose: med['dose']?.toString(),
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
        dose: med['dose']?.toString(),
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
