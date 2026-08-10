import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LabResult {
  final String imagePath;
  final String description;
  final String? imageBase64;

  const LabResult({
    required this.imagePath,
    required this.description,
    this.imageBase64,
  });

  Map<String, dynamic> toJson() => {
        'imagePath': imagePath,
        'description': description,
        'imageBase64': imageBase64,
      };

  factory LabResult.fromJson(Map<String, dynamic> json) => LabResult(
        imagePath: json['imagePath']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        imageBase64: json['imageBase64']?.toString(),
      );
}

class LabResultsProvider extends ChangeNotifier {
  static const String _storageKey = 'lab_results_v1';

  final List<LabResult> _entries = [];

  List<LabResult> get entries => List.unmodifiable(_entries);

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
                .map((item) => LabResult.fromJson(Map<String, dynamic>.from(item))),
          );
      }
    } catch (_) {
      _entries.clear();
    }

    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = _entries.map((entry) => entry.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(payload));
  }

  Future<void> add(LabResult entry) async {
    _entries.insert(0, entry);
    await _saveToPrefs();
    notifyListeners();
  }

  Future<void> update(int index, LabResult entry) async {
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
