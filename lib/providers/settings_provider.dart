import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/patient_data_sync_service.dart';

enum PatientGender { male, female }

class SettingsProvider extends ChangeNotifier {
  String _name = 'زائر';
  int? _age;
  PatientGender? _gender;
  Color _themeColor = const Color(0xFF36BBA0);
  List<String> _chronicDiseases = [];
  bool _drugKnowledgeEnabled = false;
  String _vibrationPattern = 'default';
  int _targetSystolic = 120;
  int _targetDiastolic = 80;
  int _targetBloodSugar = 100;
  String _language = 'ar'; // 'ar' for Arabic, 'en' for English

  String get name => _name;
  int? get age => _age;
  PatientGender? get gender => _gender;
  Color get themeColor => _themeColor;
  List<String> get chronicDiseases => List.unmodifiable(_chronicDiseases);
  bool get drugKnowledgeEnabled => _drugKnowledgeEnabled;
  String get vibrationPattern => _vibrationPattern;
  int get targetSystolic => _targetSystolic;
  int get targetDiastolic => _targetDiastolic;
  int get targetBloodSugar => _targetBloodSugar;
  String get language => _language;

  void _syncCloudInBackground() {
    unawaited(
      PatientDataSyncService()
          .syncLocalToCloudIfAuthenticated()
          .catchError((e) {
            debugPrint('[SettingsProvider] Background sync failed: $e');
          }),
    );
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _name = prefs.getString('settings_name') ?? 'زائر';
    _age = prefs.getInt('settings_age');
    _drugKnowledgeEnabled = prefs.getBool('settings_drug_knowledge') ?? false;
    _vibrationPattern = prefs.getString('settings_vibration') ?? 'default';
    
    final g = prefs.getString('settings_gender');
    if (g != null) {
      _gender = g == 'male' ? PatientGender.male : PatientGender.female;
    }
    
    final colorVal = prefs.getInt('settings_theme_color');
    if (colorVal != null) {
      _themeColor = Color(colorVal);
    }
    
    final diseases = prefs.getStringList('settings_chronic_diseases');
    if (diseases != null) {
      _chronicDiseases = diseases;
    }
    
    _targetSystolic = prefs.getInt('settings_target_systolic') ?? 120;
    _targetDiastolic = prefs.getInt('settings_target_diastolic') ?? 80;
    _targetBloodSugar = prefs.getInt('settings_target_blood_sugar') ?? 100;
    _language = prefs.getString('settings_language') ?? 'ar';
    
    notifyListeners();
  }

  Future<void> setName(String v) async {
    _name = v.trim().isEmpty ? 'زائر' : v.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('settings_name', _name);
    notifyListeners();
    _syncCloudInBackground();
  }

  Future<void> setAge(int? v) async {
    _age = v;
    final prefs = await SharedPreferences.getInstance();
    if (v == null) {
      await prefs.remove('settings_age');
    } else {
      await prefs.setInt('settings_age', v);
    }
    notifyListeners();
    _syncCloudInBackground();
  }

  Future<void> setGender(PatientGender? v) async {
    _gender = v;
    final prefs = await SharedPreferences.getInstance();
    if (v == null) {
      await prefs.remove('settings_gender');
    } else {
      await prefs.setString('settings_gender', v == PatientGender.male ? 'male' : 'female');
    }
    notifyListeners();
    _syncCloudInBackground();
  }

  Future<void> setThemeColor(Color c) async {
    _themeColor = c;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('settings_theme_color', c.value);
    notifyListeners();
    _syncCloudInBackground();
  }

  Future<void> toggleChronicDisease(String disease) async {
    const noDiseases = 'لا توجد أمراض مزمنة';
    
    if (_chronicDiseases.contains(disease)) {
      _chronicDiseases.remove(disease);
    } else {
      // If selecting "no chronic diseases", clear all other diseases
      if (disease == noDiseases) {
        _chronicDiseases.clear();
      } else {
        // If selecting a disease, remove "no chronic diseases" option
        _chronicDiseases.remove(noDiseases);
      }
      _chronicDiseases.add(disease);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('settings_chronic_diseases', _chronicDiseases);
    notifyListeners();
    _syncCloudInBackground();
  }

  Future<void> setDrugKnowledge(bool v) async {
    _drugKnowledgeEnabled = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('settings_drug_knowledge', v);
    notifyListeners();
    _syncCloudInBackground();
  }

  Future<void> setVibrationPattern(String v) async {
    _vibrationPattern = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('settings_vibration', v);
    notifyListeners();
    _syncCloudInBackground();
  }

  Future<void> setTargetSystolic(int v) async {
    _targetSystolic = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('settings_target_systolic', v);
    notifyListeners();
    _syncCloudInBackground();
  }

  Future<void> setTargetDiastolic(int v) async {
    _targetDiastolic = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('settings_target_diastolic', v);
    notifyListeners();
    _syncCloudInBackground();
  }

  Future<void> setTargetBloodSugar(int v) async {
    _targetBloodSugar = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('settings_target_blood_sugar', v);
    notifyListeners();
    _syncCloudInBackground();
  }

  Future<void> setLanguage(String lang) async {
    _language = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('settings_language', lang);
    notifyListeners();
    _syncCloudInBackground();
  }
}
