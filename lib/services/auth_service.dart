import 'package:flutter/material.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  bool _isAuthenticated = false;
  String? _userId;
  String? _userEmail;
  String? _userName;
  String? _errorMessage;
  bool _isLoading = false;

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  String? get userId => _userId;
  String? get userEmail => _userEmail;
  String? get userName => _userName;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    _isAuthenticated = _apiService.isAuthenticated();
    _userId = _apiService.userId;
    debugPrint('[AuthService] Initialized, isAuthenticated: $_isAuthenticated');
    notifyListeners();
  }

  Future<bool> register({
    required String email,
    required String password,
    required String name,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.register(
        email: email,
        password: password,
        name: name,
      );

      _isAuthenticated = true;
      _userId = response['userId'];
      _userEmail = email;
      _userName = name;
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
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.login(
        email: email,
        password: password,
      );

      _isAuthenticated = true;
      _userId = response['userId'];
      _userEmail = email;
      _userName = response['name'];
      debugPrint('[AuthService] Login successful for: $email');
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
      _userEmail = null;
      _userName = null;
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
