import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../providers/medication_provider.dart';
import '../providers/adherence_provider.dart';

class NotificationService {
  NotificationService._privateConstructor();
  static final NotificationService _instance = NotificationService._privateConstructor();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  GlobalKey<NavigatorState>? _navigatorKey;
  // Queue payloads that arrive before a Navigator/Context is ready
  final List<Map<String, dynamic>> _pendingTaps = <Map<String, dynamic>>[];

  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
    debugPrint('[NotificationService] navigatorKey set. Flushing any pending taps...');
    _flushPendingTaps();
  }

  Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();

    // Set the local timezone from the platform so scheduled times are correct
    try {
      final String localTz = await FlutterNativeTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTz));
    } catch (_) {
      // If timezone lookup fails, the default timezone will be used (UTC); continue safely.
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    final ios = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    await _plugin.initialize(
      InitializationSettings(android: android, iOS: ios),
      // Handle tap on notification
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        try {
          final payload = response.payload;
          if (payload == null || payload.isEmpty) return;
          final Map<String, dynamic> data = jsonDecode(payload) as Map<String, dynamic>;
          debugPrint('[NotificationService] onDidReceiveNotificationResponse with payload. navigatorReady=${_navigatorKey != null}');
          // If navigator/context isn't ready yet, enqueue and flush later
          if (_navigatorKey == null || _navigatorKey!.currentContext == null) {
            _pendingTaps.add(data);
            _scheduleFlush();
          } else {
            _handleNotificationTap(data);
          }
        } catch (e) {
          debugPrint('[NotificationService] ERROR in onDidReceiveNotificationResponse: $e');
        }
      },
    );

    // Ensure the notification channel exists with high importance for Android 8+
    try {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.createNotificationChannel(
        const AndroidNotificationChannel(
          'medicine_channel',
          'Medicine reminders',
          description: 'Reminders to take medicines',
          importance: Importance.max,
          enableVibration: true,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('notification'),
        ),
      );
      debugPrint('[NotificationService] Medicine channel created/verified');
    } catch (e) {
      debugPrint('[NotificationService] Error creating channel: $e');
    }

    // Request Android runtime permissions when available
    try {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.requestNotificationsPermission();
      await androidImpl?.requestExactAlarmsPermission();
    } catch (_) {}

    // If the app was launched by tapping a notification while terminated, capture it now
    try {
      final details = await _plugin.getNotificationAppLaunchDetails();
      if (details?.didNotificationLaunchApp == true && details?.notificationResponse?.payload != null) {
        final payload = details!.notificationResponse!.payload!;
        debugPrint('[NotificationService] App launched via notification. Queueing initial payload');
        final Map<String, dynamic> data = jsonDecode(payload) as Map<String, dynamic>;
        _pendingTaps.add(data);
        _scheduleFlush();
      }
    } catch (e) {
      debugPrint('[NotificationService] Error reading launch details: $e');
    }

    _initialized = true;
  }

  int _idFor(String prefix, int offset) => prefix.hashCode ^ offset;

  // Track active timers for testing/fallback purposes
  final Map<int, Timer> _activeTimers = {};

  Future<void> scheduleRepeatedOccurrences({
    required String prefix,
    required String title,
    required String body,
    required DateTime firstOccurrence,
    required int intervalHours,
    int occurrences = 30,
  }) async {
    await init();
    debugPrint('[NotificationService] scheduleRepeatedOccurrences called: prefix=$prefix, title=$title, firstOccurrence=$firstOccurrence, intervalHours=$intervalHours, occurrences=$occurrences');

    final prefs = await SharedPreferences.getInstance();
    final key = 'notifs_$prefix';

    final List<int> ids = [];
    int scheduledCount = 0;
    bool isFirstOccurrence = true;

    for (var i = 0; i < occurrences; i++) {
      final scheduled = firstOccurrence.add(Duration(hours: intervalHours * i));
      final now = DateTime.now();
      debugPrint('[NotificationService] Occurrence $i: scheduled=$scheduled, now=$now, isBefore=${scheduled.isBefore(now)}');
      if (scheduled.isBefore(now)) {
        debugPrint('[NotificationService] Skipping occurrence $i (in the past)');
        continue;
      }
      final id = _idFor(prefix, i + 1);
      ids.add(id);
      scheduledCount++;

      final payload = jsonEncode({
        'prefix': prefix,
        'name': title.replaceFirst('Time to take ', ''),
        'dose': body,
        'id': id,
        'scheduled': scheduled.millisecondsSinceEpoch,
      });

      try {
        debugPrint('[NotificationService] Scheduling notification $scheduledCount: id=$id, for=$scheduled (T+${scheduled.difference(now).inSeconds}s from now)');
        final tzDateTime = tz.TZDateTime(
          tz.local,
          scheduled.year,
          scheduled.month,
          scheduled.day,
          scheduled.hour,
          scheduled.minute,
          scheduled.second,
        );
        debugPrint('[NotificationService] Converted to TZDateTime: $tzDateTime (system TZ: ${tz.local})');
        
        // Attempt zonedSchedule (system scheduling)
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          tzDateTime,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'medicine_channel',
              'Medicine reminders',
              channelDescription: 'Reminders to take medicines',
              importance: Importance.max,
              priority: Priority.high,
              playSound: true,
              fullScreenIntent: true,
              audioAttributesUsage: AudioAttributesUsage.alarm,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: payload,
        );
        debugPrint('[NotificationService] Successfully scheduled notification id=$id with zonedSchedule');

        // FALLBACK: For the first occurrence, also set a Timer as a safety net
        // This ensures at least one test fires reliably on emulator
        if (isFirstOccurrence) {
          _scheduleTimerFallback(id, title, body, scheduled, payload);
          isFirstOccurrence = false;
        }
      } on PlatformException catch (e) {
        debugPrint('[NotificationService] PlatformException for id=$id: ${e.code} - ${e.message}');
        if (e.code == 'exact_alarms_not_permitted') {
          debugPrint('[NotificationService] Retrying with inexactAllowWhileIdle for id=$id');
          await _plugin.zonedSchedule(
            id,
            title,
            body,
            tz.TZDateTime(
              tz.local,
              scheduled.year,
              scheduled.month,
              scheduled.day,
              scheduled.hour,
              scheduled.minute,
              scheduled.second,
            ),
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'medicine_channel',
                'Medicine reminders',
                channelDescription: 'Reminders to take medicines',
                importance: Importance.max,
                priority: Priority.high,
                playSound: true,
                fullScreenIntent: true,
              ),
              iOS: DarwinNotificationDetails(),
            ),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            payload: payload,
          );
          debugPrint('[NotificationService] Successfully scheduled with inexact for id=$id');
        } else {
          debugPrint('[NotificationService] Re-throwing exception: $e');
          rethrow;
        }
      } catch (e, st) {
        debugPrint('[NotificationService] Unexpected error for id=$id: $e\n$st');
        continue;
      }
    }

    await prefs.setString(key, jsonEncode(ids));
    debugPrint('[NotificationService] Completed scheduling for prefix=$prefix, total scheduled=$scheduledCount');
    print('Scheduled notification ids for $prefix: ${ids.join(', ')}');
  }

  Future<void> cancelForPrefix(String prefix) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'notifs_$prefix';
    if (!prefs.containsKey(key)) return;
    final raw = prefs.getString(key);
    if (raw == null) return;
    final List<dynamic> ids = jsonDecode(raw);
    for (final dynamic d in ids) {
      final id = d as int;
      await _plugin.cancel(id);
      // Cancel any active timer for this id as well
      _activeTimers[id]?.cancel();
      _activeTimers.remove(id);
    }
    await prefs.remove(key);
  }

  /// Fallback Timer-based scheduling for testing on emulator (first occurrence only)
  void _scheduleTimerFallback(int id, String title, String body, DateTime when, String payload) {
    // Cancel any existing timer for this id
    _activeTimers[id]?.cancel();

    final now = DateTime.now();
    final delayMs = when.difference(now).inMilliseconds;

    if (delayMs <= 0) {
      debugPrint('[NotificationService] Timer fallback: time is in the past, skipping');
      return;
    }

    debugPrint('[NotificationService] Timer fallback set for id=$id, fires in ${(delayMs / 1000).toStringAsFixed(1)}s');

    _activeTimers[id] = Timer(Duration(milliseconds: delayMs), () async {
      debugPrint('[NotificationService] Timer fallback FIRED for id=$id');
      
      // Show the notification in the system tray
      await _plugin.show(
        id,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'medicine_channel',
            'Medicine reminders',
            channelDescription: 'Reminders to take medicines',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            fullScreenIntent: true,
            audioAttributesUsage: AudioAttributesUsage.alarm,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: payload,
      );
      debugPrint('[NotificationService] Timer notification shown to tray');
      
      // If app is in foreground, also show the dialog immediately (without requiring a tap)
      if (_navigatorKey != null && _navigatorKey!.currentContext != null) {
        debugPrint('[NotificationService] App in foreground, showing dialog immediately');
        final Map<String, dynamic> data = jsonDecode(payload);
        _handleNotificationTap(data);
      } else {
        debugPrint('[NotificationService] App not in foreground, notification only (user will tap to see dialog)');
      }
      
      _activeTimers.remove(id);
    });
  }

  // Handler called when a notification is tapped (or delivered and tapped)
  Future<void> _handleNotificationTap(Map<String, dynamic> data) async {
    // Ensure we have a navigator and a context; otherwise, enqueue and retry
    if (_navigatorKey == null || _navigatorKey!.currentContext == null) {
      debugPrint('[NotificationService] Context not ready, enqueueing tap');
      _pendingTaps.add(data);
      _scheduleFlush();
      return;
    }

    final context = _navigatorKey!.currentContext!;

    final String? prefix = data['prefix'] as String?;
    final String name = (data['name'] as String?) ?? 'Medication';
    final String dose = (data['dose'] as String?) ?? '';
    final int? id = data['id'] as int?;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
            contentPadding: EdgeInsets.zero,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFF1EBEA6), Color(0xFF05B3A7)]),
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                  ),
                  child: Column(
                    children: [
                      const CircleAvatar(radius: 28, backgroundColor: Colors.white, child: Icon(Icons.medication, color: Color(0xFF05B3A7), size: 32)),
                      const SizedBox(height: 12),
                      Text('حان وقت الدواء!', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.black)),
                      const SizedBox(height: 6),
                      Text(dose, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF36BBA0), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                          onPressed: () async {
                            Navigator.of(ctx).pop();
                            if (prefix != null) {
                              try {
                                // Mark taken: reschedule future occurrences starting from now + interval
                                final medProv = Provider.of<MedicationProvider>(context, listen: false);
                                medProv.recordTaken(prefix);
                                
                                // Record adherence
                                final adherence = Provider.of<AdherenceProvider>(context, listen: false);
                                await adherence.recordTaken(
                                  medicationName: name,
                                  dose: dose,
                                );
                              } catch (_) {}
                            }
                          },
                          icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                          label: const Text('أخذت الدواء', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                Navigator.of(ctx).pop();
                                // Skip: cancel only this one occurrence
                                if (id != null && prefix != null) {
                                  await cancelById(id, prefix);
                                }
                              },
                              child: const Text('تخطي'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF3D27A)),
                              onPressed: () async {
                                Navigator.of(ctx).pop();
                                // Snooze for 15 minutes
                                if (prefix != null) {
                                  final when = DateTime.now().add(const Duration(minutes: 15));
                                  await scheduleOneOff(prefix: prefix, title: 'Time to take $name', body: dose, when: when);
                                }
                              },
                              child: const Text('غفوة (15)'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _scheduleFlush() {
    // Try on next frame to allow navigator to become available
    WidgetsBinding.instance.addPostFrameCallback((_) => _flushPendingTaps());
    // Also schedule a small delayed retry as a fallback on cold start
    Future<void>.delayed(const Duration(milliseconds: 200), _flushPendingTaps);
  }

  void _flushPendingTaps() {
    if (_navigatorKey == null || _navigatorKey!.currentContext == null) {
      debugPrint('[NotificationService] Flush skipped: context still not ready');
      return;
    }
    if (_pendingTaps.isEmpty) return;
    debugPrint('[NotificationService] Flushing ${_pendingTaps.length} pending notification tap(s)');
    final items = List<Map<String, dynamic>>.from(_pendingTaps);
    _pendingTaps.clear();
    for (final data in items) {
      _handleNotificationTap(data);
    }
  }

  /// Send an immediate test notification (no scheduling) to debug channel/tap flow
  Future<void> sendTestNotification() async {
    await init();
    final id = DateTime.now().millisecondsSinceEpoch & 0x7fffffff;
    debugPrint('[NotificationService] Sending IMMEDIATE test notification, id=$id');
    try {
      await _plugin.show(
        id,
        'Test Notification',
        'Tap me to verify the dialog shows!',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'medicine_channel',
            'Medicine reminders',
            channelDescription: 'Reminders to take medicines',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            fullScreenIntent: true,
            audioAttributesUsage: AudioAttributesUsage.alarm,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: jsonEncode({
          'prefix': 'test',
          'name': 'Test',
          'dose': 'Tap to verify',
          'id': id,
          'scheduled': DateTime.now().millisecondsSinceEpoch,
        }),
      );
      debugPrint('[NotificationService] Test notification sent successfully');
    } catch (e) {
      debugPrint('[NotificationService] Error sending test notification: $e');
    }
  }

  /// Public helper to display the alarm UI for a payload (useful for debug/testing)
  void showAlarmForPayload(Map<String, dynamic> payload) {
    _handleNotificationTap(payload);
  }

  Future<void> cancelById(int id, String prefix) async {
    await _plugin.cancel(id);
    final prefs = await SharedPreferences.getInstance();
    final key = 'notifs_$prefix';
    if (!prefs.containsKey(key)) return;
    final raw = prefs.getString(key);
    if (raw == null) return;
    final List<dynamic> ids = jsonDecode(raw);
    ids.removeWhere((element) => element == id);
    await prefs.setString(key, jsonEncode(ids));
  }

  Future<int> scheduleOneOff({
    required String prefix,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    await init();
    final id = DateTime.now().millisecondsSinceEpoch & 0x7fffffff;
    final payload = jsonEncode({'prefix': prefix, 'name': title.replaceFirst('Time to take ', ''), 'dose': body, 'id': id, 'scheduled': when.millisecondsSinceEpoch});
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(when, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'medicine_channel',
          'Medicine reminders',
          channelDescription: 'Reminders to take medicines',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          fullScreenIntent: true,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
    return id;
  }

  /// Show an immediate alert-style notification (used for health warnings)
  Future<void> showAlertNotification({required String title, required String body}) async {
    await init();
    final id = DateTime.now().millisecondsSinceEpoch & 0x7fffffff;
    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'health_alerts',
          'Health Alerts',
          channelDescription: 'Immediate health alerts',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}