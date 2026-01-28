import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/material.dart';

class ApiService {
  ApiService._privateConstructor();
  static final ApiService _instance = ApiService._privateConstructor();
  factory ApiService() => _instance;

  // Change this to your backend URL
  static const String _baseUrl = 'http://localhost:5000/api';
  // For mobile testing, use: 'http://192.168.x.x:5000/api' (your machine's IP)
  
  late http.Client _httpClient;
  String? _authToken;
  String? _userId;

  Future<void> init() async {
    _httpClient = http.Client();
    await _loadAuthToken();
    debugPrint('[ApiService] Initialized with baseUrl: $_baseUrl');
  }

  Future<void> _loadAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
    _userId = prefs.getString('user_id');
    debugPrint('[ApiService] Loaded auth token: ${_authToken != null ? 'Yes' : 'No'}');
  }

  Future<void> _saveAuthToken(String token, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('user_id', userId);
    _authToken = token;
    _userId = userId;
    debugPrint('[ApiService] Saved auth token for user: $userId');
  }

  Map<String, String> _getHeaders() {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  // ==================== AUTHENTICATION ====================

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: _getHeaders(),
        body: jsonEncode({
          'email': email,
          'password': password,
          'name': name,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        await _saveAuthToken(data['token'], data['userId']);
        debugPrint('[ApiService] Registration successful');
        return data;
      } else {
        throw Exception('Registration failed: ${response.body}');
      }
    } catch (e) {
      debugPrint('[ApiService] Registration error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: _getHeaders(),
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        await _saveAuthToken(data['token'], data['userId']);
        debugPrint('[ApiService] Login successful');
        return data;
      } else {
        throw Exception('Login failed: ${response.body}');
      }
    } catch (e) {
      debugPrint('[ApiService] Login error: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _httpClient.post(
        Uri.parse('$_baseUrl/auth/logout'),
        headers: _getHeaders(),
      );
    } catch (e) {
      debugPrint('[ApiService] Logout error: $e');
    } finally {
      _authToken = null;
      _userId = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_id');
    }
  }

  bool isAuthenticated() => _authToken != null && _userId != null;
  String? get userId => _userId;

  // ==================== MEDICATIONS ====================

  Future<List<Map<String, dynamic>>> getMedications() async {
    if (!isAuthenticated()) throw Exception('Not authenticated');
    
    try {
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/medications'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to fetch medications: ${response.body}');
      }
    } catch (e) {
      debugPrint('[ApiService] Get medications error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> addMedication({
    required String name,
    required String dose,
    required int intervalHours,
    required DateTime nextDose,
    String? notes,
    int? quantity,
  }) async {
    if (!isAuthenticated()) throw Exception('Not authenticated');

    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/medications'),
        headers: _getHeaders(),
        body: jsonEncode({
          'name': name,
          'dose': dose,
          'intervalHours': intervalHours,
          'nextDose': nextDose.toIso8601String(),
          'notes': notes,
          'quantity': quantity,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('[ApiService] Medication added: ${data['id']}');
        return data;
      } else {
        throw Exception('Failed to add medication: ${response.body}');
      }
    } catch (e) {
      debugPrint('[ApiService] Add medication error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateMedication({
    required String medicationId,
    required String name,
    required String dose,
    required int intervalHours,
    required DateTime nextDose,
    String? notes,
    int? quantity,
  }) async {
    if (!isAuthenticated()) throw Exception('Not authenticated');

    try {
      final response = await _httpClient.put(
        Uri.parse('$_baseUrl/medications/$medicationId'),
        headers: _getHeaders(),
        body: jsonEncode({
          'name': name,
          'dose': dose,
          'intervalHours': intervalHours,
          'nextDose': nextDose.toIso8601String(),
          'notes': notes,
          'quantity': quantity,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('[ApiService] Medication updated: $medicationId');
        return data;
      } else {
        throw Exception('Failed to update medication: ${response.body}');
      }
    } catch (e) {
      debugPrint('[ApiService] Update medication error: $e');
      rethrow;
    }
  }

  Future<void> deleteMedication(String medicationId) async {
    if (!isAuthenticated()) throw Exception('Not authenticated');

    try {
      final response = await _httpClient.delete(
        Uri.parse('$_baseUrl/medications/$medicationId'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('Failed to delete medication: ${response.body}');
      }
      debugPrint('[ApiService] Medication deleted: $medicationId');
    } catch (e) {
      debugPrint('[ApiService] Delete medication error: $e');
      rethrow;
    }
  }

  // ==================== BLOOD PRESSURE ====================

  Future<List<Map<String, dynamic>>> getBloodPressureRecords() async {
    if (!isAuthenticated()) throw Exception('Not authenticated');

    try {
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/blood-pressure'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to fetch blood pressure records: ${response.body}');
      }
    } catch (e) {
      debugPrint('[ApiService] Get blood pressure error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> addBloodPressure({
    required int systolic,
    required int diastolic,
    required DateTime timestamp,
    String? notes,
  }) async {
    if (!isAuthenticated()) throw Exception('Not authenticated');

    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/blood-pressure'),
        headers: _getHeaders(),
        body: jsonEncode({
          'systolic': systolic,
          'diastolic': diastolic,
          'timestamp': timestamp.toIso8601String(),
          'notes': notes,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('[ApiService] Blood pressure record added: ${data['id']}');
        return data;
      } else {
        throw Exception('Failed to add blood pressure record: ${response.body}');
      }
    } catch (e) {
      debugPrint('[ApiService] Add blood pressure error: $e');
      rethrow;
    }
  }

  // ==================== BLOOD SUGAR ====================

  Future<List<Map<String, dynamic>>> getBloodSugarRecords() async {
    if (!isAuthenticated()) throw Exception('Not authenticated');

    try {
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/blood-sugar'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to fetch blood sugar records: ${response.body}');
      }
    } catch (e) {
      debugPrint('[ApiService] Get blood sugar error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> addBloodSugar({
    required double value,
    required String unit,
    required DateTime timestamp,
    String? notes,
  }) async {
    if (!isAuthenticated()) throw Exception('Not authenticated');

    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/blood-sugar'),
        headers: _getHeaders(),
        body: jsonEncode({
          'value': value,
          'unit': unit,
          'timestamp': timestamp.toIso8601String(),
          'notes': notes,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('[ApiService] Blood sugar record added: ${data['id']}');
        return data;
      } else {
        throw Exception('Failed to add blood sugar record: ${response.body}');
      }
    } catch (e) {
      debugPrint('[ApiService] Add blood sugar error: $e');
      rethrow;
    }
  }

  // ==================== ADHERENCE ====================

  Future<void> recordMedicationTaken({
    required String medicationId,
    required DateTime timestamp,
  }) async {
    if (!isAuthenticated()) throw Exception('Not authenticated');

    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/adherence/record'),
        headers: _getHeaders(),
        body: jsonEncode({
          'medicationId': medicationId,
          'timestamp': timestamp.toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 201) {
        throw Exception('Failed to record adherence: ${response.body}');
      }
      debugPrint('[ApiService] Adherence recorded for medication: $medicationId');
    } catch (e) {
      debugPrint('[ApiService] Record adherence error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getAdherenceStats() async {
    if (!isAuthenticated()) throw Exception('Not authenticated');

    try {
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/adherence/stats'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data;
      } else {
        throw Exception('Failed to fetch adherence stats: ${response.body}');
      }
    } catch (e) {
      debugPrint('[ApiService] Get adherence stats error: $e');
      rethrow;
    }
  }

  // ==================== APPOINTMENTS ====================

  Future<List<Map<String, dynamic>>> getAppointments() async {
    if (!isAuthenticated()) throw Exception('Not authenticated');

    try {
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/appointments'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to fetch appointments: ${response.body}');
      }
    } catch (e) {
      debugPrint('[ApiService] Get appointments error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> addAppointment({
    required String title,
    required DateTime dateTime,
    String? location,
    String? notes,
    String? doctorName,
  }) async {
    if (!isAuthenticated()) throw Exception('Not authenticated');

    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/appointments'),
        headers: _getHeaders(),
        body: jsonEncode({
          'title': title,
          'dateTime': dateTime.toIso8601String(),
          'location': location,
          'notes': notes,
          'doctorName': doctorName,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('[ApiService] Appointment added: ${data['id']}');
        return data;
      } else {
        throw Exception('Failed to add appointment: ${response.body}');
      }
    } catch (e) {
      debugPrint('[ApiService] Add appointment error: $e');
      rethrow;
    }
  }

  Future<void> deleteAppointment(String appointmentId) async {
    if (!isAuthenticated()) throw Exception('Not authenticated');

    try {
      final response = await _httpClient.delete(
        Uri.parse('$_baseUrl/appointments/$appointmentId'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('Failed to delete appointment: ${response.body}');
      }
      debugPrint('[ApiService] Appointment deleted: $appointmentId');
    } catch (e) {
      debugPrint('[ApiService] Delete appointment error: $e');
      rethrow;
    }
  }

  void dispose() {
    _httpClient.close();
  }
}
