import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'api_service.dart';

class GoogleAuthResult {
  final String userId;
  final String username;
  final String? email;
  final String name;
  final String userType;

  const GoogleAuthResult({
    required this.userId,
    required this.username,
    required this.email,
    required this.name,
    required this.userType,
  });
}

class GoogleAuthService {
  GoogleAuthService({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    ApiService? apiService,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: const ['email']),
        _apiService = apiService ?? ApiService();

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final ApiService _apiService;

  Future<GoogleAuthResult> signIn() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Google sign-in was cancelled');
    }

    final googleAuth = await googleUser.authentication;
    if (googleAuth.idToken == null) {
      throw Exception('Google sign-in did not return an ID token');
    }

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    final firebaseUser = userCredential.user;
    if (firebaseUser == null) {
      throw Exception('Google sign-in succeeded without a Firebase user');
    }

    final firebaseIdToken = await firebaseUser.getIdToken(true);
    if (firebaseIdToken == null || firebaseIdToken.isEmpty) {
      throw Exception('Firebase ID token is missing after Google sign-in');
    }

    final response = await _apiService.loginWithGoogle(
      firebaseIdToken: firebaseIdToken,
    );

    debugPrint('[GoogleAuth] Signed in as ${response['username']}');

    return GoogleAuthResult(
      userId: response['userId'].toString(),
      username: response['username']?.toString() ?? '',
      email: response['email']?.toString(),
      name: response['name']?.toString() ?? '',
      userType: response['userType']?.toString() ?? '',
    );
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _firebaseAuth.signOut();
  }
}