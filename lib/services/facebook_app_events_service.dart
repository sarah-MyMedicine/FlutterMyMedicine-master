import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:flutter/foundation.dart';

class FacebookAppEventsService {
  FacebookAppEventsService._();

  static final FacebookAppEventsService _instance =
      FacebookAppEventsService._();

  factory FacebookAppEventsService() => _instance;

  final FacebookAppEvents _events = FacebookAppEvents();

  Future<void> activateApp() async {
    if (kIsWeb) return;

    try {
      await _events.activateApp();
    } catch (error) {
      debugPrint('[FacebookAppEvents] Activation failed: $error');
    }
  }

  Future<void> logEvent(
    String name, {
    Map<String, dynamic>? parameters,
    double? valueToSum,
    bool flush = false,
  }) async {
    if (kIsWeb) return;

    try {
      await _events.logEvent(
        name: name,
        parameters: parameters,
        valueToSum: valueToSum,
      );
      if (flush) await _events.flush();
    } catch (error) {
      debugPrint('[FacebookAppEvents] Event $name failed: $error');
    }
  }

  Future<void> logLogin({required String method}) => logEvent(
        'fb_mobile_login',
        parameters: {'method': method},
      );

  Future<void> logRegistration({required String method}) => logEvent(
        'fb_mobile_complete_registration',
        parameters: {'method': method},
      );
}
