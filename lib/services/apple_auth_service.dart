import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

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

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<AppleAuthResult> signIn() async {
    if (!isSupportedOnPlatform) {
      throw Exception('Sign in with Apple is only available on iOS');
    }

    final rawNonce = _generateNonce();
    final nonce = _sha256ofString(rawNonce);

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: const [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
      nonce: nonce,
    );

    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
    );

    final userCredential = await _firebaseAuth.signInWithCredential(
      oauthCredential,
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