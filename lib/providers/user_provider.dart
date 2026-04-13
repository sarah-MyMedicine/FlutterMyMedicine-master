import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/google_auth_service.dart';
import '../services/patient_data_sync_service.dart';
import '../services/push_notification_service.dart';

class UserProvider extends ChangeNotifier {
  String? _username;
  String? _email;
  String? _name;
  String? _userType;
  String? _userId;
  String? _password;
  String? _lastError;
  bool _isLoggedIn = false;

  String? get username => _username;
  String? get email => _email;
  String? get name => _name;
  String? get userType => _userType;
  String? get userId => _userId;
  String? get password => _password;
  String? get lastError => _lastError;
  bool get isLoggedIn => _isLoggedIn;
  bool get isPatient => _userType == 'patient';
  bool get isCaregiver => _userType == 'caregiver';

  String _friendlyError(Object error) {
    final raw = error.toString().replaceFirst('Exception: ', '').trim();
    if (raw == 'Username already exists') {
      return 'This username is given, please choose another one\nاسم المستخدم مستخدم بالفعل، يرجى اختيار اسم آخر';
    }
    if (raw == 'Email already exists') {
      return 'This email is already registered, please use another one\nهذا البريد الإلكتروني مسجل بالفعل، يرجى استخدام بريد آخر';
    }
    if (raw.contains('Unable to reach authentication server')) {
      return 'تعذر الوصول إلى خادم المصادقة. تأكد من تشغيل الـ Backend وأن الهاتف والكمبيوتر على نفس شبكة Wi-Fi، أو استخدم رابط Backend منشور (Public URL) عبر --dart-define=API_BASE_URL=https://<your-backend-domain>/api';
    }
    if (raw.contains('timed out') || raw.contains('TimeoutException')) {
      return 'انتهت مهلة الاتصال بالخادم. تأكد من تشغيل الـ Backend وأن الهاتف والكمبيوتر على نفس شبكة Wi-Fi، أو استخدم رابط Backend منشور (Public URL) عبر --dart-define=API_BASE_URL=https://<your-backend-domain>/api';
    }
    if (raw.contains('Connection refused') ||
        raw.contains('Failed host lookup') ||
        raw.contains('SocketException')) {
      return 'تعذر الاتصال بالخادم. تأكد من تشغيل الـ Backend وأن الهاتف والكمبيوتر على نفس شبكة Wi-Fi، أو استخدم رابط Backend منشور (Public URL) عبر --dart-define=API_BASE_URL=https://<your-backend-domain>/api';
    }
    if (raw.isEmpty) return 'حدث خطأ غير متوقع.';
    return raw;
  }

  Future<void> loadUserFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    _username = prefs.getString('username');
    _email = prefs.getString('email');
    _name = prefs.getString('name');
    _userType = prefs.getString('userType');
    _userId = prefs.getString('userId');
    _password = prefs.getString('password');
    _isLoggedIn = _username != null;
    notifyListeners();
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required String name,
    required String userType,
  }) async {
    _lastError = null;

    try {
      final apiService = ApiService();
      final response = await apiService.register(
        username: username.trim().toLowerCase(),
        email: email.trim().toLowerCase(),
        password: password,
        name: name,
        userType: userType,
      );

      await _signInToFirebase(response);

      await _saveUserData(
        username:
            response['username']?.toString() ?? username.trim().toLowerCase(),
        email: response['email']?.toString() ?? email.trim().toLowerCase(),
        name: response['name']?.toString() ?? name,
        userType: response['userType']?.toString() ?? userType,
        userId: response['userId'],
        password: password,
      );

      await _saveInitialPersonalDetailsName(
        response['name']?.toString() ?? name,
      );

      unawaited(PushNotificationService().syncTokenToBackend());

      return true;
    } catch (e) {
      _lastError = _friendlyError(e);
      debugPrint('Registration error: $_lastError');
      notifyListeners();
      return false;
    }
  }

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    _lastError = null;
    try {
      final apiService = ApiService();
      final response = await apiService.login(
        username: username.trim().toLowerCase(),
        password: password,
      );

      await _signInToFirebase(response);

      await _saveUserData(
        username:
            response['username']?.toString() ?? username.trim().toLowerCase(),
        email: response['email']?.toString(),
        name: response['name']?.toString() ?? '',
        userType: response['userType']?.toString() ?? '',
        userId: response['userId'],
        password: password,
      );

      unawaited(PushNotificationService().syncTokenToBackend());

      return true;
    } catch (e) {
      _lastError = _friendlyError(e);
      debugPrint('Login error: $_lastError');
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    _lastError = null;

    try {
      final response = await GoogleAuthService().signIn();

      await _saveUserData(
        username: response.username,
        email: response.email,
        name: response.name,
        userType: response.userType,
        userId: response.userId,
        password: null,
      );

      unawaited(PushNotificationService().syncTokenToBackend());
      return true;
    } catch (e) {
      _lastError = _friendlyError(e);
      debugPrint('Google sign-in error: $_lastError');
      notifyListeners();
      return false;
    }
  }

  /// Requests a password-reset email to be sent to the given address.
  /// The backend generates the Firebase link and emails it — the link is
  /// never returned to the client, preventing account-takeover attacks.
  Future<bool> requestPasswordReset({required String email}) async {
    _lastError = null;

    try {
      await ApiService().requestPasswordReset(
        email: email.trim().toLowerCase(),
      );
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = _friendlyError(e);
      notifyListeners();
      return false;
    }
  }

  Future<void> _saveUserData({
    required String username,
    required String? email,
    required String name,
    required String userType,
    required String userId,
    required String? password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
    if (email != null && email.isNotEmpty) {
      await prefs.setString('email', email);
    } else {
      await prefs.remove('email');
    }
    await prefs.setString('name', name);
    await prefs.setString('userType', userType);
    await prefs.setString('userId', userId);
    if (password != null) {
      await prefs.setString('password', password);
    } else {
      await prefs.remove('password');
    }

    _username = username;
    _email = email;
    _name = name;
    _userType = userType;
    _userId = userId;
    _password = password;
    _isLoggedIn = true;
    notifyListeners();
  }

  Future<void> _signInToFirebase(Map<String, dynamic> response) async {
    final customToken = response['firebaseCustomToken']?.toString();
    if (customToken == null || customToken.isEmpty) {
      throw Exception('Firebase custom token is missing from backend response');
    }

    await FirebaseAuth.instance.signInWithCustomToken(customToken);
  }

  Future<void> _saveInitialPersonalDetailsName(String rawName) async {
    final normalizedName = rawName.trim();
    if (normalizedName.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('settings_name', normalizedName);
  }

  Future<void> logout({BuildContext? context}) async {
    final currentUsername = _username;

    // Fire-and-forget: token clear is best-effort, never block logout on it
    PushNotificationService().clearTokenFromBackend().catchError((_) {});
    GoogleAuthService().signOut().catchError((_) {});

    try {
      await ApiService().logout().timeout(const Duration(seconds: 3));
    } catch (_) {}

    if (context != null) {
      await PatientDataSyncService().clearLocalDataForLogout(
        username: currentUsername,
        context: context,
      );
    } else {
      await PatientDataSyncService().clearLocalDataForLogout(
        username: currentUsername,
      );
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('username');
    await prefs.remove('email');
    await prefs.remove('name');
    await prefs.remove('userType');
    await prefs.remove('userId');
    await prefs.remove('password');
    await prefs.remove('patient_data_owner_username');

    _username = null;
    _email = null;
    _name = null;
    _userType = null;
    _userId = null;
    _password = null;
    _lastError = null;
    _isLoggedIn = false;
    notifyListeners();
  }
}
