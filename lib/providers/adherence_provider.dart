import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AdherenceProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _records = [];

  List<Map<String, dynamic>> get records {
    // Return only records from the past 30 days, sorted by date descending
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    return _records
        .where((r) {
          final timestamp = DateTime.tryParse(r['timestamp'] ?? '');
          return timestamp != null && timestamp.isAfter(cutoff);
        })
        .toList()
      ..sort((a, b) {
        final aTime = DateTime.tryParse(a['timestamp'] ?? '') ?? DateTime.now();
        final bTime = DateTime.tryParse(b['timestamp'] ?? '') ?? DateTime.now();
        return bTime.compareTo(aTime); // Descending
      });
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
        _records = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
        notifyListeners();
      } catch (_) {}
    }
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('adherence_records', jsonEncode(_records));
  }

  /// Record that a medication was taken
  Future<void> recordTaken({
    required String medicationName,
    required String dose,
    DateTime? takenAt,
  }) async {
    final timestamp = takenAt ?? DateTime.now();
    _records.add({
      'medicationName': medicationName,
      'dose': dose,
      'timestamp': timestamp.toIso8601String(),
    });
    await _saveToPrefs();
    notifyListeners();
  }

  /// Clear all adherence records (optional utility)
  Future<void> clearAll() async {
    _records.clear();
    await _saveToPrefs();
    notifyListeners();
  }
}
