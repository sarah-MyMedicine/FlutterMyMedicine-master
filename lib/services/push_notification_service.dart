import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'api_service.dart';
import 'notification_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // If Firebase is not configured yet, we keep the handler safe and silent.
  }

  debugPrint('[Push] Background message: ${message.messageId} type=${message.data['type']}');
}

class PushNotificationService {
  PushNotificationService._privateConstructor();
  static final PushNotificationService _instance = PushNotificationService._privateConstructor();
  factory PushNotificationService() => _instance;

  bool _initialized = false;
  bool _firebaseReady = false;
  StreamSubscription<String>? _tokenRefreshSubscription;

  Future<void> initialize({required bool isLoggedIn}) async {
    if (_initialized) {
      if (isLoggedIn) {
        await syncTokenToBackend();
      }
      return;
    }

    if (kIsWeb) {
      debugPrint('[Push] Web push is not configured in this project.');
      _initialized = true;
      return;
    }

    try {
      await Firebase.initializeApp();
      _firebaseReady = true;
    } catch (e) {
      debugPrint('[Push] Firebase initialization failed: $e');
      _initialized = true;
      return;
    }

    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('[Push] Notification permission: ${settings.authorizationStatus}');

    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final title = message.notification?.title ?? 'Care Alert';
      final body = message.notification?.body ?? message.data['body']?.toString() ?? '';

      if (body.isNotEmpty) {
        await NotificationService().showAlertNotification(title: title, body: body);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[Push] Message opened app: ${message.data}');
    });

    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('[Push] App launched from push notification: ${initialMessage.data}');
    }

    _tokenRefreshSubscription = messaging.onTokenRefresh.listen((token) async {
      debugPrint('[Push] FCM token refreshed');
      await _sendTokenToBackend(token);
    });

    _initialized = true;

    if (isLoggedIn) {
      await syncTokenToBackend();
    }
  }

  Future<void> syncTokenToBackend() async {
    if (!_firebaseReady) return;
    if (!ApiService().isAuthenticated()) return;

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      await _sendTokenToBackend(token);
    } catch (e) {
      debugPrint('[Push] Failed to sync token: $e');
    }
  }

  Future<void> clearTokenFromBackend() async {
    if (!ApiService().isAuthenticated()) return;

    try {
      await ApiService().clearFcmToken();
    } catch (e) {
      debugPrint('[Push] Failed to clear token from backend: $e');
    }
  }

  Future<void> _sendTokenToBackend(String token) async {
    if (!ApiService().isAuthenticated()) return;

    try {
      await ApiService().registerFcmToken(token);
      debugPrint('[Push] FCM token registered to backend');
    } catch (e) {
      debugPrint('[Push] Backend token registration failed: $e');
    }
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
  }
}
