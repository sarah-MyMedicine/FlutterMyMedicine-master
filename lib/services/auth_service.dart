import 'package:flutter/material.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  bool _isAuthenticated = false;
  String? _userId;
  String? _username;
  String? _userName;
  String? _userType;
  String? _errorMessage;
  bool _isLoading = false;

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  String? get userId => _userId;
  String? get username => _username;
  String? get userName => _userName;
  String? get userType => _userType;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isPatient => _userType == 'patient';
  bool get isCaregiver => _userType == 'caregiver';

  Future<void> init() async {
    _isAuthenticated = _apiService.isAuthenticated();
    _userId = _apiService.userId;
    debugPrint('[AuthService] Initialized, isAuthenticated: $_isAuthenticated');
    notifyListeners();
  }

  Future<bool> register({
    required String username,
    required String password,
    required String name,
    required String userType,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.register(
        username: username,
        password: password,
        name: name,
        userType: userType,
      );

      _isAuthenticated = true;
      _userId = response['userId'];
      _username = username;
      _userName = name;
      _userType = userType;
      debugPrint('[AuthService] Registration successful');
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Registration failed: $e';
      _isAuthenticated = false;
      debugPrint('[AuthService] Registration error: $e');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.login(
        username: username,
        password: password,
      );

      _isAuthenticated = true;
      _userId = response['userId'];
      _username = username;
      _userName = response['name'];
      _userType = response['userType'];
      debugPrint('[AuthService] Login successful for: $username');
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Login failed: $e';
      _isAuthenticated = false;
      debugPrint('[AuthService] Login error: $e');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.logout();
      _isAuthenticated = false;
      _userId = null;
      _username = null;
      _userName = null;
      _userType = null;
      _errorMessage = null;
      debugPrint('[AuthService] Logout successful');
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Logout failed: $e';
      debugPrint('[AuthService] Logout error: $e');
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
