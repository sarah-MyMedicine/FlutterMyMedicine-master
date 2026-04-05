import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'api_service.dart';

class WhatsAppOtpRequestResult {
  final String sessionId;
  final int expiresInSeconds;
  final String? developmentCode;

  const WhatsAppOtpRequestResult({
    required this.sessionId,
    required this.expiresInSeconds,
    this.developmentCode,
  });
}

class WhatsAppAuthResult {
  final String userId;
  final String username;
  final String name;
  final String userType;
  final String? phoneNumber;
  final String firebaseUid;

  const WhatsAppAuthResult({
    required this.userId,
    required this.username,
    required this.name,
    required this.userType,
    required this.phoneNumber,
    required this.firebaseUid,
  });
}

class WhatsAppAuthService {
  WhatsAppAuthService({
    FirebaseAuth? firebaseAuth,
    ApiService? apiService,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _apiService = apiService ?? ApiService();

  final FirebaseAuth _firebaseAuth;
  final ApiService _apiService;

  Future<WhatsAppOtpRequestResult> requestOtp({
    required String phoneNumber,
    required String purpose,
    String? username,
    String? name,
    String? userType,
  }) async {
    final response = await _apiService.requestWhatsAppOtp(
      phoneNumber: phoneNumber,
      purpose: purpose,
      username: username,
      name: name,
      userType: userType,
    );

    return WhatsAppOtpRequestResult(
      sessionId: response['sessionId'].toString(),
      expiresInSeconds: (response['expiresInSeconds'] as num?)?.toInt() ?? 0,
      developmentCode: response['developmentCode']?.toString(),
    );
  }

  Future<WhatsAppAuthResult> verifyOtp({
    required String sessionId,
    required String code,
  }) async {
    final response = await _apiService.verifyWhatsAppOtp(
      sessionId: sessionId,
      code: code,
    );

    final firebaseCustomToken = response['firebaseCustomToken']?.toString();
    if (firebaseCustomToken == null || firebaseCustomToken.isEmpty) {
      throw Exception('Firebase custom token is missing from backend response');
    }

    final userCredential = await _firebaseAuth.signInWithCustomToken(
      firebaseCustomToken,
    );
    final firebaseUser = userCredential.user;
    if (firebaseUser == null) {
      throw Exception('Firebase sign-in succeeded without a user');
    }

    debugPrint('[WhatsAppAuth] Signed in with Firebase UID ${firebaseUser.uid}');

    return WhatsAppAuthResult(
      userId: response['userId'].toString(),
      username: response['username']?.toString() ?? '',
      name: response['name']?.toString() ?? '',
      userType: response['userType']?.toString() ?? '',
      phoneNumber: response['phoneNumber']?.toString(),
      firebaseUid: firebaseUser.uid,
    );
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}
