import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PatientGender { male, female }

class SettingsProvider extends ChangeNotifier {
  String _name = 'زائر';
  int? _age;
  PatientGender? _gender;
  String? _country;
  String? _province;
  Color _themeColor = const Color(0xFF36BBA0);
  List<String> _chronicDiseases = [];
  bool _drugKnowledgeEnabled = false;
  String _vibrationPattern = 'default';

  String get name => _name;
  int? get age => _age;
  PatientGender? get gender => _gender;
  String? get country => _country;
  String? get province => _province;
  Color get themeColor => _themeColor;
  List<String> get chronicDiseases => List.unmodifiable(_chronicDiseases);
  bool get drugKnowledgeEnabled => _drugKnowledgeEnabled;
  String get vibrationPattern => _vibrationPattern;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _name = prefs.getString('settings_name') ?? 'زائر';
    _age = prefs.getInt('settings_age');
    _country = prefs.getString('settings_country');
    _province = prefs.getString('settings_province');
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
    
    notifyListeners();
  }

  Future<void> setName(String v) async {
    _name = v.trim().isEmpty ? 'زائر' : v.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('settings_name', _name);
    notifyListeners();
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
  }

  Future<void> setCountry(String? v) async {
    _country = v;
    final prefs = await SharedPreferences.getInstance();
    if (v == null || v.isEmpty) {
      await prefs.remove('settings_country');
    } else {
      await prefs.setString('settings_country', v);
    }
    notifyListeners();
  }

  Future<void> setProvince(String? v) async {
    _province = v;
    final prefs = await SharedPreferences.getInstance();
    if (v == null || v.isEmpty) {
      await prefs.remove('settings_province');
    } else {
      await prefs.setString('settings_province', v);
    }
    notifyListeners();
  }

  Future<void> setThemeColor(Color c) async {
    _themeColor = c;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('settings_theme_color', c.value);
    notifyListeners();
  }

  Future<void> toggleChronicDisease(String disease) async {
    if (_chronicDiseases.contains(disease)) {
      _chronicDiseases.remove(disease);
    } else {
      _chronicDiseases.add(disease);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('settings_chronic_diseases', _chronicDiseases);
    notifyListeners();
  }

  Future<void> setDrugKnowledge(bool v) async {
    _drugKnowledgeEnabled = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('settings_drug_knowledge', v);
    notifyListeners();
  }

  Future<void> setVibrationPattern(String v) async {
    _vibrationPattern = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('settings_vibration', v);
    notifyListeners();
  }
}
