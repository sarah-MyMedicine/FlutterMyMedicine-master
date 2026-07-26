import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SymptomEntry {
  final String title;
  final String potentialDrug;
  final String notes;
  final String severity;
  final String dateLabel;

  const SymptomEntry({
    required this.title,
    required this.potentialDrug,
    required this.notes,
    required this.severity,
    required this.dateLabel,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'potentialDrug': potentialDrug,
        'notes': notes,
        'severity': severity,
        'dateLabel': dateLabel,
      };

  factory SymptomEntry.fromJson(Map<String, dynamic> json) => SymptomEntry(
        title: json['title']?.toString() ?? '',
        potentialDrug: json['potentialDrug']?.toString() ?? '',
        notes: json['notes']?.toString() ?? '',
        severity: json['severity']?.toString() ?? '',
        dateLabel: json['dateLabel']?.toString() ?? '',
      );
}

class SymptomLogProvider extends ChangeNotifier {
  static const String _storageKey = 'symptom_log_entries_v1';

  final List<SymptomEntry> _entries = [];

  List<SymptomEntry> get entries => List.unmodifiable(_entries);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    if (raw == null || raw.isEmpty) {
      _entries.clear();
      notifyListeners();
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        _entries
          ..clear()
          ..addAll(
            decoded
                .whereType<Map>()
                .map((item) => SymptomEntry.fromJson(Map<String, dynamic>.from(item))),
          );
      }
    } catch (_) {
      _entries.clear();
    }

    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = _entries.map((e) => e.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(payload));
  }

  Future<void> add(SymptomEntry entry) async {
    _entries.insert(0, entry);
    await _saveToPrefs();
    notifyListeners();
  }

  Future<void> update(int index, SymptomEntry entry) async {
    if (index < 0 || index >= _entries.length) return;
    _entries[index] = entry;
    await _saveToPrefs();
    notifyListeners();
  }

  Future<void> remove(int index) async {
    if (index < 0 || index >= _entries.length) return;
    _entries.removeAt(index);
    await _saveToPrefs();
    notifyListeners();
  }
}