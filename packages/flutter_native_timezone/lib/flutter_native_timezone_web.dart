import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

///
/// The plugin class for the web, acts as the plugin inside bits
/// and connects to the js world.
///
class FlutterNativeTimezonePlugin {
  static void registerWith(Registrar registrar) {
    final MethodChannel channel = MethodChannel(
        'flutter_native_timezone',
        const StandardMethodCodec(),
        registrar.messenger);
    final FlutterNativeTimezonePlugin instance = FlutterNativeTimezonePlugin();
    channel.setMethodCallHandler(instance.handleMethodCall);
  }

  Future<dynamic> handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'getLocalTimezone':
        return _getLocalTimeZone();
      case 'getAvailableTimezones':
        return [ _getLocalTimeZone() ];
      default:
        throw PlatformException(
            code: 'Unimplemented',
            details: "The flutter_native_timezone plugin for web doesn't implement "
                "the method '${call.method}'");
    }
  }

  /// Platform-specific implementation of determining the user's
  /// local time zone when running on the web.
  ///
  String _getLocalTimeZone() {
    final timeZoneName = DateTime.now().timeZoneName;
    if (timeZoneName.isEmpty) {
      return 'UTC';
    }
    return timeZoneName;
  }
}

