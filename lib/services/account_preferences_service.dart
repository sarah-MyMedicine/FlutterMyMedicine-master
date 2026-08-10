import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class AccountPreferencesService {
  static const String _accountPreferencesKey = 'account_preferences_v1';

  static Future<Map<String, dynamic>> loadAccountPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_accountPreferencesKey);
    if (raw == null || raw.isEmpty) return <String, dynamic>{};

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}

    return <String, dynamic>{};
  }

  static Future<void> saveAccountPreferences(Map<String, dynamic> values) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accountPreferencesKey, jsonEncode(values));
  }

  static Future<void> clearAccountPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accountPreferencesKey);
  }
}
