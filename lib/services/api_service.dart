import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';

class ApiService {
  ApiService._privateConstructor();
  static final ApiService _instance = ApiService._privateConstructor();
  factory ApiService() => _instance;

  static const String _defaultBaseUrl = 'http://localhost:5000/api';
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const Duration _authTimeout = Duration(seconds: 8);
  static const String _lastAuthBaseUrlKey = 'last_auth_base_url';

  // Use --dart-define=API_BASE_URL=http://<ip>:5000/api for physical devices.
  String get _baseUrl {
    if (_resolvedAuthBaseUrl != null && _resolvedAuthBaseUrl!.isNotEmpty) {
      return _resolvedAuthBaseUrl!;
    }

    if (_envBaseUrl.isNotEmpty) return _envBaseUrl;
    if (kIsWeb) return _defaultBaseUrl;
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000/api';
    }
    return _defaultBaseUrl;
  }

  late http.Client _httpClient;
  String? _authToken;
  String? _userId;
  String? _resolvedAuthBaseUrl;

  Future<void> init() async {
    _httpClient = http.Client();
    await _loadAuthToken();
    debugPrint('[ApiService] Initialized with baseUrl: $_baseUrl');
  }

  List<String> _authBaseUrlCandidates() {
    final candidates = <String>[];
    final seen = <String>{};

    void addCandidate(String url) {
      if (url.isEmpty || seen.contains(url)) return;
      seen.add(url);
      candidates.add(url);
    }

    if (_resolvedAuthBaseUrl != null && _resolvedAuthBaseUrl!.isNotEmpty) {
      addCandidate(_resolvedAuthBaseUrl!);
    }

    if (_envBaseUrl.isNotEmpty) {
      addCandidate(_envBaseUrl);
    }

    if (kIsWeb) {
      addCandidate(_defaultBaseUrl);
      return candidates;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      // Prefer localhost variants first for real devices when adb reverse is active,
      // then emulator host mapping.
      addCandidate('http://127.0.0.1:5000/api');
      addCandidate('http://localhost:5000/api');
      addCandidate('http://10.0.2.2:5000/api');
      return candidates;
    }

    addCandidate(_defaultBaseUrl);
    return candidates;
  }

  Future<http.Response> _postAuthWithFailover(
    String path,
    Map<String, dynamic> body,
  ) async {
    final candidates = _authBaseUrlCandidates();
    final failures = <String>[];

    for (final base in candidates) {
      try {
        final response = await _httpClient
            .post(
              Uri.parse('$base$path'),
              headers: _getHeaders(),
              body: jsonEncode(body),
            )
            .timeout(_authTimeout);

        _resolvedAuthBaseUrl = base;
        await _saveResolvedAuthBaseUrl(base);
        return response;
      } on TimeoutException {
        failures.add('$base -> timeout');
      } catch (e) {
        failures.add('$base -> ${e.toString()}');
      }
    }

    final attempted = candidates.join(', ');
    final details = failures.isEmpty ? 'No connection details available.' : failures.join(' | ');
    throw Exception(
      'Unable to reach authentication server. Tried: $attempted. $details',
    );
  }

  String _extractApiError(http.Response response, String fallback) {
    try {
      final dynamic decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message']?.toString();
        if (message != null && message.isNotEmpty) return message;
      }
    } catch (_) {
      // Keep fallback when server body is not JSON.
    }
    return '$fallback (HTTP ${response.statusCode})';
  }

  Future<void> _loadAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
    _userId = prefs.getString('user_id');
    _resolvedAuthBaseUrl = prefs.getString(_lastAuthBaseUrlKey);
    debugPrint(
      '[ApiService] Loaded auth token: ${_authToken != null ? 'Yes' : 'No'}',
    );
  }

  Future<void> _saveResolvedAuthBaseUrl(String baseUrl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastAuthBaseUrlKey, baseUrl);
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
    required String username,
    required String password,
    required String name,
    required String userType,
    required String registrationSource,
  }) async {
    try {
      final response = await _postAuthWithFailover('/auth/register', {
        'username': username,
        'password': password,
        'name': name,
        'userType': userType,
        'registrationSource': registrationSource,
      });

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        await _saveAuthToken(data['token'], data['userId']);
        debugPrint('[ApiService] Registration successful');
        return data;
      } else {
        throw Exception(_extractApiError(response, 'Registration failed'));
      }
    } on TimeoutException {
      throw Exception(
        'انتهت مهلة الاتصال بالخادم. تأكد أن الـ backend يعمل وأن عنوان API صحيح.',
      );
    } catch (e) {
      debugPrint('[ApiService] Registration error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _postAuthWithFailover('/auth/login', {
        'username': username,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        await _saveAuthToken(data['token'], data['userId']);
        debugPrint('[ApiService] Login successful');
        return data;
      } else {
        throw Exception(_extractApiError(response, 'Login failed'));
      }
    } on TimeoutException {
      throw Exception(
        'انتهت مهلة الاتصال بالخادم. تأكد أن الـ backend يعمل وأن عنوان API صحيح.',
      );
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

  // ==================== PATIENT DATA SYNC ====================

  Future<Map<String, dynamic>> getPatientDataSnapshot() async {
    if (!isAuthenticated()) throw Exception('Not authenticated');

    try {
      final response = await _httpClient
          .get(Uri.parse('$_baseUrl/patient-data'), headers: _getHeaders())
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final snapshot = data['data'];
        if (snapshot is Map<String, dynamic>) {
          return snapshot;
        }
        return <String, dynamic>{};
      }

      throw Exception('Failed to fetch patient data: ${response.body}');
    } catch (e) {
      debugPrint('[ApiService] Get patient data error: $e');
      rethrow;
    }
  }

  Future<void> savePatientDataSnapshot(Map<String, dynamic> data) async {
    if (!isAuthenticated()) throw Exception('Not authenticated');

    try {
      final response = await _httpClient
          .put(
            Uri.parse('$_baseUrl/patient-data'),
            headers: _getHeaders(),
            body: jsonEncode({'data': data}),
          )
          .timeout(const Duration(seconds: 25));

      if (response.statusCode != 200) {
        throw Exception('Failed to save patient data: ${response.body}');
      }
    } catch (e) {
      debugPrint('[ApiService] Save patient data error: $e');
      rethrow;
    }
  }

  // ==================== MEDICATIONS ====================

  Future<List<Map<String, dynamic>>> getMedications() async {
    if (!isAuthenticated()) throw Exception('Not authenticated');

    try {
      final response = await _httpClient
          .get(Uri.parse('$_baseUrl/medications'), headers: _getHeaders())
          .timeout(const Duration(seconds: 15));

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
      final response = await _httpClient
          .post(
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
          )
          .timeout(const Duration(seconds: 15));

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
      final response = await _httpClient
          .put(
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
          )
          .timeout(const Duration(seconds: 15));

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
      final response = await _httpClient
          .delete(
            Uri.parse('$_baseUrl/medications/$medicationId'),
            headers: _getHeaders(),
          )
          .timeout(const Duration(seconds: 15));

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
      final response = await _httpClient
          .get(Uri.parse('$_baseUrl/blood-pressure'), headers: _getHeaders())
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception(
          'Failed to fetch blood pressure records: ${response.body}',
        );
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
      final response = await _httpClient
          .post(
            Uri.parse('$_baseUrl/blood-pressure'),
            headers: _getHeaders(),
            body: jsonEncode({
              'systolic': systolic,
              'diastolic': diastolic,
              'timestamp': timestamp.toIso8601String(),
              'notes': notes,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('[ApiService] Blood pressure record added: ${data['id']}');
        return data;
      } else {
        throw Exception(
          'Failed to add blood pressure record: ${response.body}',
        );
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
      final response = await _httpClient
          .get(Uri.parse('$_baseUrl/blood-sugar'), headers: _getHeaders())
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception(
          'Failed to fetch blood sugar records: ${response.body}',
        );
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
      final response = await _httpClient
          .post(
            Uri.parse('$_baseUrl/blood-sugar'),
            headers: _getHeaders(),
            body: jsonEncode({
              'value': value,
              'unit': unit,
              'timestamp': timestamp.toIso8601String(),
              'notes': notes,
            }),
          )
          .timeout(const Duration(seconds: 15));

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
      final response = await _httpClient
          .post(
            Uri.parse('$_baseUrl/adherence/record'),
            headers: _getHeaders(),
            body: jsonEncode({
              'medicationId': medicationId,
              'timestamp': timestamp.toIso8601String(),
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 201) {
        throw Exception('Failed to record adherence: ${response.body}');
      }
      debugPrint(
        '[ApiService] Adherence recorded for medication: $medicationId',
      );
    } catch (e) {
      debugPrint('[ApiService] Record adherence error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getAdherenceStats() async {
    if (!isAuthenticated()) throw Exception('Not authenticated');

    try {
      final response = await _httpClient
          .get(Uri.parse('$_baseUrl/adherence/stats'), headers: _getHeaders())
          .timeout(const Duration(seconds: 15));

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
      final response = await _httpClient
          .get(Uri.parse('$_baseUrl/appointments'), headers: _getHeaders())
          .timeout(const Duration(seconds: 15));

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
      final response = await _httpClient
          .post(
            Uri.parse('$_baseUrl/appointments'),
            headers: _getHeaders(),
            body: jsonEncode({
              'title': title,
              'dateTime': dateTime.toIso8601String(),
              'location': location,
              'notes': notes,
              'doctorName': doctorName,
            }),
          )
          .timeout(const Duration(seconds: 15));

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
      final response = await _httpClient
          .delete(
            Uri.parse('$_baseUrl/appointments/$appointmentId'),
            headers: _getHeaders(),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('Failed to delete appointment: ${response.body}');
      }
      debugPrint('[ApiService] Appointment deleted: $appointmentId');
    } catch (e) {
      debugPrint('[ApiService] Delete appointment error: $e');
      rethrow;
    }
  }

  // ==================== CAREGIVER LINKING ====================

  Future<Map<String, dynamic>> generateInvitation(String username) async {
    if (!isAuthenticated()) throw Exception('Not authenticated');

    try {
      final response = await _httpClient
          .post(
            Uri.parse('$_baseUrl/caregiver/generate-invitation'),
            headers: _getHeaders(),
            body: jsonEncode({'username': username}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint(
          '[ApiService] Invitation generated: ${data['invitationCode']}',
        );
        return data;
      } else {
        throw Exception('Failed to generate invitation: ${response.body}');
      }
    } catch (e) {
      debugPrint('[ApiService] Generate invitation error: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getPendingInvitations(
    String username,
  ) async {
    if (!isAuthenticated()) throw Exception('Not authenticated');

    try {
      final response = await _httpClient
          .get(
            Uri.parse('$_baseUrl/caregiver/invitations/$username'),
            headers: _getHeaders(),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> invitations = data['invitations'] as List<dynamic>;
        return invitations.cast<Map<String, dynamic>>();
      } else {
        return [];
      }
    } catch (e) {
      debugPrint('[ApiService] Get pending invitations error: $e');
      return [];
    }
  }

  Future<bool> acceptInvitation({
    required String invitationCode,
    required String caregiverUsername,
  }) async {
    if (!isAuthenticated()) throw Exception('Not authenticated');

    try {
      final response = await _httpClient
          .post(
            Uri.parse('$_baseUrl/caregiver/accept-invitation'),
            headers: _getHeaders(),
            body: jsonEncode({
              'invitationCode': invitationCode,
              'caregiverUsername': caregiverUsername,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        debugPrint('[ApiService] Invitation accepted: $invitationCode');
        return true;
      } else {
        debugPrint(
          '[ApiService] Failed to accept invitation: ${response.body}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('[ApiService] Accept invitation error: $e');
      return false;
    }
  }

  Future<bool> rejectInvitation(String invitationCode) async {
    if (!isAuthenticated()) throw Exception('Not authenticated');

    try {
      final response = await _httpClient
          .post(
            Uri.parse('$_baseUrl/caregiver/reject-invitation'),
            headers: _getHeaders(),
            body: jsonEncode({'invitationCode': invitationCode}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        debugPrint('[ApiService] Invitation rejected: $invitationCode');
        return true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('[ApiService] Reject invitation error: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getLinkedPatients(
    String caregiverUsername,
  ) async {
    if (!isAuthenticated()) throw Exception('Not authenticated');

    try {
      final response = await _httpClient
          .get(
            Uri.parse('$_baseUrl/caregiver/patients/$caregiverUsername'),
            headers: _getHeaders(),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> patients = data['patients'] as List<dynamic>;
        return patients.cast<Map<String, dynamic>>();
      } else {
        return [];
      }
    } catch (e) {
      debugPrint('[ApiService] Get linked patients error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getLinkedCaregiver(
    String patientUsername,
  ) async {
    if (!isAuthenticated()) throw Exception('Not authenticated');

    try {
      final response = await _httpClient
          .get(
            Uri.parse('$_baseUrl/caregiver/caregiver/$patientUsername'),
            headers: _getHeaders(),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['caregiver'] as Map<String, dynamic>?;
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('[ApiService] Get linked caregiver error: $e');
      return null;
    }
  }

  Future<void> unlinkCaregiver({
    required String patientUsername,
    required String caregiverUsername,
  }) async {
    if (!isAuthenticated()) throw Exception('Not authenticated');

    try {
      final response = await _httpClient
          .post(
            Uri.parse('$_baseUrl/caregiver/unlink'),
            headers: _getHeaders(),
            body: jsonEncode({
              'patientUsername': patientUsername,
              'caregiverUsername': caregiverUsername,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        debugPrint('[ApiService] Caregiver unlinked');
      } else {
        throw Exception('Failed to unlink caregiver: ${response.body}');
      }
    } catch (e) {
      debugPrint('[ApiService] Unlink caregiver error: $e');
      rethrow;
    }
  }

  Future<void> notifyMissedDoses({
    required String patientUsername,
    required int consecutiveMissed,
    required String medicationName,
  }) async {
    if (!isAuthenticated()) throw Exception('Not authenticated');

    try {
      final response = await _httpClient
          .post(
            Uri.parse('$_baseUrl/caregiver/notify-missed-dose'),
            headers: _getHeaders(),
            body: jsonEncode({
              'patientUsername': patientUsername,
              'consecutiveMissed': consecutiveMissed,
              'medicationName': medicationName,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        debugPrint('[ApiService] Missed dose notification sent');
      }
    } catch (e) {
      debugPrint('[ApiService] Notify missed doses error: $e');
    }
  }

  Future<Map<String, dynamic>> sendEmergencyAlert({
    required String patientUsername,
    String classification = 'siren',
    String? message,
  }) async {
    if (!isAuthenticated()) throw Exception('Not authenticated');

    try {
      final response = await _httpClient
          .post(
            Uri.parse('$_baseUrl/caregiver/notify-emergency'),
            headers: _getHeaders(),
            body: jsonEncode({
              'patientUsername': patientUsername,
              'classification': classification,
              if (message != null && message.trim().isNotEmpty)
                'message': message.trim(),
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('[ApiService] Emergency alert sent: ${data['alertId']}');
        return data;
      }

      throw Exception(
        _extractApiError(response, 'Failed to send emergency alert'),
      );
    } catch (e) {
      debugPrint('[ApiService] Send emergency alert error: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getCaregiverAlerts(
    String caregiverUsername,
  ) async {
    if (!isAuthenticated()) throw Exception('Not authenticated');

    try {
      final response = await _httpClient
          .get(
            Uri.parse('$_baseUrl/caregiver/alerts/$caregiverUsername'),
            headers: _getHeaders(),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> alerts =
            data['alerts'] as List<dynamic>? ?? <dynamic>[];
        return alerts.cast<Map<String, dynamic>>();
      }

      throw Exception(
        _extractApiError(response, 'Failed to load caregiver alerts'),
      );
    } catch (e) {
      debugPrint('[ApiService] Get caregiver alerts error: $e');
      return [];
    }
  }

  Future<void> markEmergencyAlertAsRead(String alertId) async {
    if (!isAuthenticated()) throw Exception('Not authenticated');

    try {
      final response = await _httpClient
          .patch(
            Uri.parse('$_baseUrl/caregiver/alerts/$alertId/read'),
            headers: _getHeaders(),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception(
          _extractApiError(response, 'Failed to mark alert as read'),
        );
      }
    } catch (e) {
      debugPrint('[ApiService] Mark emergency alert as read error: $e');
      rethrow;
    }
  }

  Future<void> registerFcmToken(String fcmToken) async {
    if (!isAuthenticated()) throw Exception('Not authenticated');

    final response = await _httpClient
        .post(
          Uri.parse('$_baseUrl/caregiver/register-fcm-token'),
          headers: _getHeaders(),
          body: jsonEncode({'fcmToken': fcmToken}),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(
        _extractApiError(response, 'Failed to register FCM token'),
      );
    }
  }

  Future<void> clearFcmToken() async {
    if (!isAuthenticated()) throw Exception('Not authenticated');

    final response = await _httpClient
        .post(
          Uri.parse('$_baseUrl/caregiver/clear-fcm-token'),
          headers: _getHeaders(),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(_extractApiError(response, 'Failed to clear FCM token'));
    }
  }

  void dispose() {
    _httpClient.close();
  }
}
