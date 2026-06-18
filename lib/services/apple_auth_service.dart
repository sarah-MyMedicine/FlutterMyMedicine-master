import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'api_service.dart';

class AppleAuthResult {
  final String userId;
  final String username;
  final String? email;
  final String name;
  final String userType;

  const AppleAuthResult({
    required this.userId,
    required this.username,
    required this.email,
    required this.name,
    required this.userType,
  });
}

class AppleAuthService {
  AppleAuthService({
    FirebaseAuth? firebaseAuth,
    ApiService? apiService,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _apiService = apiService ?? ApiService();

  final FirebaseAuth _firebaseAuth;
  final ApiService _apiService;

  static bool get isSupportedOnPlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<AppleAuthResult> signIn() async {
    if (!isSupportedOnPlatform) {
      throw Exception('Sign in with Apple is only available on iOS');
    }

    final appleProvider = AppleAuthProvider();
    appleProvider.addScope('email');
    appleProvider.addScope('name');

    final userCredential = await _firebaseAuth.signInWithProvider(
      appleProvider,
    );
    final firebaseUser = userCredential.user;
    if (firebaseUser == null) {
      throw Exception('Apple sign-in succeeded without a Firebase user');
    }

    final firebaseIdToken = await firebaseUser.getIdToken(true);
    if (firebaseIdToken == null || firebaseIdToken.isEmpty) {
      throw Exception('Firebase ID token is missing after Apple sign-in');
    }

    final response = await _apiService.loginWithApple(
      firebaseIdToken: firebaseIdToken,
    );

    debugPrint('[AppleAuth] Signed in as ${response['username']}');

    return AppleAuthResult(
      userId: response['userId'].toString(),
      username: response['username']?.toString() ?? '',
      email: response['email']?.toString(),
      name: response['name']?.toString() ?? '',
      userType: response['userType']?.toString() ?? '',
    );
  }
}