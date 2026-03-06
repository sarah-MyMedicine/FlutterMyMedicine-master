import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class UserProvider extends ChangeNotifier {
  String? _username;
  String? _name;
  String? _userType;
  String? _userId;
  bool _isLoggedIn = false;
  
  String? get username => _username;
  String? get name => _name;
  String? get userType => _userType;
  String? get userId => _userId;
  bool get isLoggedIn => _isLoggedIn;
  bool get isPatient => _userType == 'patient';
  bool get isCaregiver => _userType == 'caregiver';
  
  Future<void> loadUserFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    _username = prefs.getString('username');
    _name = prefs.getString('name');
    _userType = prefs.getString('userType');
    _userId = prefs.getString('userId');
    _isLoggedIn = _username != null;
    notifyListeners();
  }
  
  Future<bool> register({
    required String username,
    required String password,
    required String name,
    required String userType,
  }) async {
    try {
      final apiService = ApiService();
      final response = await apiService.register(
        username: username,
        password: password,
        name: name,
        userType: userType,
      );
      
      await _saveUserData(
        username: username,
        name: name,
        userType: userType,
        userId: response['userId'],
      );
      
      return true;
    } catch (e) {
      debugPrint('Registration error: $e');
      return false;
    }
  }
  
  Future<bool> login({
    required String username,
    required String password,
  }) async {
    try {
      final apiService = ApiService();
      final response = await apiService.login(
        username: username,
        password: password,
      );
      
      await _saveUserData(
        username: username,
        name: response['name'],
        userType: response['userType'],
        userId: response['userId'],
      );
      
      return true;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }
  
  Future<void> _saveUserData({
    required String username,
    required String name,
    required String userType,
    required String userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
    await prefs.setString('name', name);
    await prefs.setString('userType', userType);
    await prefs.setString('userId', userId);
    
    _username = username;
    _name = name;
    _userType = userType;
    _userId = userId;
    _isLoggedIn = true;
    notifyListeners();
  }
  
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('username');
    await prefs.remove('name');
    await prefs.remove('userType');
    await prefs.remove('userId');
    
    _username = null;
    _name = null;
    _userType = null;
    _userId = null;
    _isLoggedIn = false;
    notifyListeners();
  }
}
