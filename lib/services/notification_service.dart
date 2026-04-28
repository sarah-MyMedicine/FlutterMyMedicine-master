import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../providers/medication_provider.dart';
import '../providers/adherence_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/translations.dart';

class NotificationService {
  NotificationService._privateConstructor();
  static final NotificationService _instance = NotificationService._privateConstructor();
  factory NotificationService() => _instance;

  static const int recurringMedicationAlarmBudget = 420;
  static const int _maxOccurrencesPerPrefix = 14;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _darwinPermissionsRequested = false;

  GlobalKey<NavigatorState>? _navigatorKey;
  // Queue payloads that arrive before a Navigator/Context is ready
  final List<Map<String, dynamic>> _pendingTaps = <Map<String, dynamic>>[];
  final Map<int, DateTime> _handledTapIds = <int, DateTime>{};

  // Motivational messages for skipped medications
  final List<String> _skippedMedicationMessages = [
    'ندري الدواء التزام، بس مفعوله يخليك تمشي وتتونس بدون تعب! 😉',
    'الحبايه دا تباوع عليك وتگول: اشربني هسة وخلصني! 😂',
    'وينك يا طيب؟ اشتاقينا للالتزام مالتك، لا تخلي السلسلة تنقطع!',
  ];

  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
    debugPrint('[NotificationService] navigatorKey set. Flushing any pending taps...');
    _flushPendingTaps();
  }

  Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();

    // Set the local timezone - fallback to UTC if not found
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Baghdad'));
    } catch (_) {
      // If timezone lookup fails, use UTC
      tz.setLocalLocation(tz.UTC);
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    final ios = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    await _plugin.initialize(
      settings: InitializationSettings(android: android, iOS: ios),
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
        ),
      );

      await androidImpl?.createNotificationChannel(
        const AndroidNotificationChannel(
          'caregiver_alerts',
          'Caregiver Alerts',
          description: 'Emergency and adherence alerts sent to caregivers',
          importance: Importance.max,
          enableVibration: true,
          playSound: true,
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

    await _ensureDarwinPermissions();
    _initialized = true;
  }

  Future<void> _ensureDarwinPermissions() async {
    if (!(Platform.isIOS || Platform.isMacOS)) return;
    if (_darwinPermissionsRequested) return;

    try {
      if (Platform.isIOS) {
        final iosImpl = _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        await iosImpl?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      } else if (Platform.isMacOS) {
        final macImpl = _plugin.resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>();
        await macImpl?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
      _darwinPermissionsRequested = true;
    } catch (e) {
      debugPrint('[NotificationService] Failed to request Darwin permissions: $e');
    }
  }

  Future<Map<String, bool?>> getReminderReliabilityStatus() async {
    await init();

    bool? notificationsEnabled;
    bool? exactAlarmsEnabled;

    try {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        notificationsEnabled = await androidImpl.areNotificationsEnabled();
        exactAlarmsEnabled = await androidImpl.canScheduleExactNotifications();
      } else {
        notificationsEnabled = true;
        exactAlarmsEnabled = true;
      }
    } catch (e) {
      debugPrint('[NotificationService] Failed to read reliability status: $e');
    }

    return {
      'notificationsEnabled': notificationsEnabled,
      'exactAlarmsEnabled': exactAlarmsEnabled,
    };
  }

  Future<bool?> requestNotificationsPermission() async {
    await init();

    try {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await androidImpl?.requestNotificationsPermission();
    } catch (e) {
      debugPrint('[NotificationService] Failed to request notification permission: $e');
      return null;
    }
  }

  Future<bool?> requestExactAlarmPermission() async {
    await init();

    try {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await androidImpl?.requestExactAlarmsPermission();
    } catch (e) {
      debugPrint('[NotificationService] Failed to request exact alarm permission: $e');
      return null;
    }
  }

  int _idFor(String prefix, int offset) => prefix.hashCode ^ offset;

  bool _isAlarmLimitException(PlatformException error) {
    final message = error.message ?? '';
    return message.contains('Maximum limit of concurrent alarms 500 reached');
  }

  Future<int> _trackedMedicationAlarmCount() async {
    final prefs = await SharedPreferences.getInstance();
    var count = 0;

    for (final key in prefs.getKeys()) {
      if (!key.startsWith('notifs_')) continue;
      final raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) continue;

      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          count += decoded.whereType<num>().length;
        }
      } catch (_) {}
    }

    return count;
  }

  Future<void> resetTrackedMedicationSchedules() async {
    await init();

    final prefs = await SharedPreferences.getInstance();
    final trackedKeys = prefs.getKeys().where((key) => key.startsWith('notifs_')).toList();

    for (final key in trackedKeys) {
      final raw = prefs.getString(key);
      if (raw != null && raw.isNotEmpty) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is List) {
            for (final value in decoded.whereType<num>()) {
              final id = value.toInt();
              await _plugin.cancel(id: id);
              _activeTimers[id]?.cancel();
              _activeTimers.remove(id);
            }
          }
        } catch (e) {
          debugPrint('[NotificationService] Failed to clear tracked ids for $key: $e');
        }
      }

      await prefs.remove(key);
    }
  }

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

    await cancelForPrefix(prefix);

    final prefs = await SharedPreferences.getInstance();
    final key = 'notifs_$prefix';

    final trackedCount = await _trackedMedicationAlarmCount();
    final availableSlots = recurringMedicationAlarmBudget - trackedCount;
    final safeOccurrences = min(
      min(occurrences, _maxOccurrencesPerPrefix),
      max(0, availableSlots),
    );

    if (safeOccurrences <= 0) {
      await prefs.remove(key);
      debugPrint('[NotificationService] No remaining tracked alarm budget for prefix=$prefix; skipping schedule');
      return;
    }

    final List<int> ids = [];
    int scheduledCount = 0;
    bool isFirstOccurrence = true;

    for (var i = 0; i < safeOccurrences; i++) {
      final scheduled = firstOccurrence.add(Duration(hours: intervalHours * i));
      final now = DateTime.now();
      // Add a 5-second safety buffer to ensure the scheduled time is sufficiently in the future
      final minimumFutureTime = now.add(const Duration(seconds: 5));
      debugPrint('[NotificationService] Occurrence $i: scheduled=$scheduled, now=$now, minimumFutureTime=$minimumFutureTime');
      if (scheduled.isBefore(minimumFutureTime)) {
        debugPrint('[NotificationService] Skipping occurrence $i (too close to now or in the past)');
        continue;
      }
      final id = _idFor(prefix, i + 1);
      ids.add(id);
      scheduledCount++;

      final payload = jsonEncode({
        'prefix': prefix,
        'name': title.replaceFirst('موعد تناول ', ''),
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
        
        // Final safety check: ensure the TZDateTime is in the future
        final nowTz = tz.TZDateTime.now(tz.local);
        if (tzDateTime.isBefore(nowTz) || tzDateTime.isAtSameMomentAs(nowTz)) {
          debugPrint('[NotificationService] TZDateTime is not in the future, skipping id=$id');
          continue;
        }
        
        // Attempt zonedSchedule (system scheduling)
        await _plugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: tzDateTime,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'medicine_channel',
              'Medicine reminders',
              channelDescription: 'Reminders to take medicines',
              importance: Importance.max,
              priority: Priority.max,
              playSound: true,
              fullScreenIntent: true,
              visibility: NotificationVisibility.public,
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
        if (_isAlarmLimitException(e)) {
          debugPrint('[NotificationService] Alarm limit reached while scheduling prefix=$prefix. Stopping further schedules for this medication.');
          if (isFirstOccurrence) {
            _scheduleTimerFallback(id, title, body, scheduled, payload);
            isFirstOccurrence = false;
          }
          break;
        }
        if (e.code == 'exact_alarms_not_permitted') {
          debugPrint('[NotificationService] Retrying with inexactAllowWhileIdle for id=$id');
          await _plugin.zonedSchedule(
            id: id,
            title: title,
            body: body,
            scheduledDate: tz.TZDateTime(
              tz.local,
              scheduled.year,
              scheduled.month,
              scheduled.day,
              scheduled.hour,
              scheduled.minute,
              scheduled.second,
            ),
            notificationDetails: const NotificationDetails(
              android: AndroidNotificationDetails(
                'medicine_channel',
                'Medicine reminders',
                channelDescription: 'Reminders to take medicines',
                importance: Importance.max,
                priority: Priority.max,
                playSound: true,
                fullScreenIntent: true,
                visibility: NotificationVisibility.public,
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
      await _plugin.cancel(id: id);
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
        id: id,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'medicine_channel',
            'Medicine reminders',
            channelDescription: 'Reminders to take medicines',
            importance: Importance.max,
            priority: Priority.max,
            playSound: true,
            fullScreenIntent: true,
            visibility: NotificationVisibility.public,
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
    final int? tapId = data['id'] is int
        ? data['id'] as int
        : int.tryParse('${data['id']}');
    if (tapId != null) {
      final now = DateTime.now();
      _handledTapIds.removeWhere(
        (_, handledAt) => now.difference(handledAt) > const Duration(hours: 6),
      );

      final alreadyHandledAt = _handledTapIds[tapId];
      if (alreadyHandledAt != null) {
        debugPrint('[NotificationService] Ignoring duplicate tap handling for id=$tapId');
        return;
      }

      _handledTapIds[tapId] = now;
    }

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
                                final adherence = Provider.of<AdherenceProvider>(context, listen: false);
                                final settings = Provider.of<SettingsProvider>(context, listen: false);
                                final lang = settings.language;
                                final prefixValue = prefix;

                                final matchedMedication = medProv.items.firstWhere(
                                  (item) => item['notifPrefix'] == prefixValue,
                                  orElse: () => <String, String?>{},
                                );
                                final canonicalName =
                                    (matchedMedication['name'] ?? '').trim().isNotEmpty
                                        ? matchedMedication['name']!.trim()
                                        : name;
                                final canonicalDose =
                                    (matchedMedication['dose'] ?? '').trim().isNotEmpty
                                        ? matchedMedication['dose']!.trim()
                                        : dose.split('·').first.trim();

                                await adherence.recordTaken(
                                  medicationName: canonicalName,
                                  dose: canonicalDose,
                                );

                                Future<void> handleTrackerOutcome(
                                  PillTrackerResult trackerResult, {
                                  required bool allowRetryAfterRefill,
                                }) async {
                                  if (trackerResult.warningAtFive) {
                                    final remaining = trackerResult.remainingPills ?? 0;
                                    final warningMessage = lang == 'ar'
                                      ? 'تبقى $remaining حبات فقط من دواء $name'
                                      : 'Only $remaining pills are left for $name';
                                    await showAlertNotification(
                                      title: AppTranslations.translate('pill_tracker_low_title', lang),
                                      body: warningMessage,
                                    );
                                  }

                                  if (!trackerResult.needsRefillInput) return;

                                  int? refillCount;
                                  while (refillCount == null) {
                                    refillCount = await _showRefillPillCountDialog(
                                      context: context,
                                      lang: lang,
                                      medicationName: name,
                                    );
                                  }

                                  await medProv.refillPills(prefixValue, refillCount);

                                  if (allowRetryAfterRefill && !trackerResult.doseRecorded) {
                                    final retryResult = await medProv.recordTaken(prefixValue);

                                    await handleTrackerOutcome(
                                      retryResult,
                                      allowRetryAfterRefill: false,
                                    );
                                  }
                                }

                                final trackerResult = await medProv.recordTaken(prefixValue);

                                await handleTrackerOutcome(
                                  trackerResult,
                                  allowRetryAfterRefill: true,
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
                                // Schedule a motivational reminder 1 hour later
                                await _scheduleSkippedMedicationReminder(name);
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
                                  await scheduleOneOff(prefix: prefix, title: 'موعد تناول $name', body: dose, when: when);
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

  Future<int?> _showRefillPillCountDialog({
    required BuildContext context,
    required String lang,
    required String medicationName,
  }) async {
    final controller = TextEditingController();
    String? errorText;

    final result = await showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(AppTranslations.translate('pill_tracker_refill_title', lang)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${AppTranslations.translate('pill_tracker_refill_body', lang)} $medicationName'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: AppTranslations.translate('pill_count_in_package', lang),
                      hintText: AppTranslations.translate('pill_tracker_refill_hint', lang),
                      errorText: errorText,
                    ),
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    final parsed = int.tryParse(controller.text.trim());
                    if (parsed == null || parsed <= 0) {
                      setState(() {
                        errorText = AppTranslations.translate('pill_tracker_refill_invalid', lang);
                      });
                      return;
                    }
                    Navigator.of(dialogContext).pop(parsed);
                  },
                  child: Text(AppTranslations.translate('pill_tracker_refill_confirm', lang)),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();
    return result;
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
        id: id,
        title: 'Test Notification',
        body: 'Tap me to verify the dialog shows!',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'medicine_channel',
            'Medicine reminders',
            channelDescription: 'Reminders to take medicines',
            importance: Importance.max,
            priority: Priority.max,
            playSound: true,
            fullScreenIntent: true,
            visibility: NotificationVisibility.public,
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
    await _plugin.cancel(id: id);
    _activeTimers[id]?.cancel();
    _activeTimers.remove(id);
    final prefs = await SharedPreferences.getInstance();
    final key = 'notifs_$prefix';
    if (!prefs.containsKey(key)) return;
    final raw = prefs.getString(key);
    if (raw == null) return;
    final List<dynamic> ids = jsonDecode(raw);
    ids.removeWhere((element) => element == id);
    if (ids.isEmpty) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, jsonEncode(ids));
    }
  }

  Future<int> scheduleOneOff({
    required String prefix,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    await init();
    
    // Ensure the scheduled time is in the future with a 5-second buffer
    final now = DateTime.now();
    final minimumFutureTime = now.add(const Duration(seconds: 5));
    if (when.isBefore(minimumFutureTime)) {
      debugPrint('[NotificationService] scheduleOneOff: scheduled time is too close or in the past, adjusting to minimum future time');
      when = minimumFutureTime;
    }
    
    final id = DateTime.now().millisecondsSinceEpoch & 0x7fffffff;
    final payload = jsonEncode({'prefix': prefix, 'name': title.replaceFirst('موعد تناول ', ''), 'dose': body, 'id': id, 'scheduled': when.millisecondsSinceEpoch});
    
    final tzDateTime = tz.TZDateTime.from(when, tz.local);
    final nowTz = tz.TZDateTime.now(tz.local);
    if (tzDateTime.isBefore(nowTz) || tzDateTime.isAtSameMomentAs(nowTz)) {
      debugPrint('[NotificationService] scheduleOneOff: TZDateTime is not in the future, skipping');
      return id;
    }
    
    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzDateTime,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'medicine_channel',
            'Medicine reminders',
            channelDescription: 'Reminders to take medicines',
            importance: Importance.max,
            priority: Priority.max,
            playSound: true,
            fullScreenIntent: true,
            visibility: NotificationVisibility.public,
            audioAttributesUsage: AudioAttributesUsage.alarm,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
    } on PlatformException catch (e) {
      if (_isAlarmLimitException(e)) {
        debugPrint('[NotificationService] Alarm limit reached for one-off schedule. Using in-memory timer fallback for id=$id');
        _scheduleTimerFallback(id, title, body, when, payload);
        return id;
      }
      rethrow;
    }
    return id;
  }

  /// Schedule a motivational reminder 1 hour after skipping medication
  Future<void> _scheduleSkippedMedicationReminder(String medicationName) async {
    await init();
    
    // Get a random message
    final random = Random();
    final message = _skippedMedicationMessages[random.nextInt(_skippedMedicationMessages.length)];
    
    // Schedule for 1 hour from now (ensure it's in the future)
    final now = DateTime.now();
    final when = now.add(const Duration(hours: 1, seconds: 5));
    final tz.TZDateTime scheduledDate = tz.TZDateTime.from(when, tz.local);
    
    // Final safety check
    final nowTz = tz.TZDateTime.now(tz.local);
    if (scheduledDate.isBefore(nowTz) || scheduledDate.isAtSameMomentAs(nowTz)) {
      debugPrint('[NotificationService] _scheduleSkippedMedicationReminder: scheduled time is not in the future, skipping');
      return;
    }
    
    final id = when.millisecondsSinceEpoch & 0x7fffffff;
    
    try {
      await _plugin.zonedSchedule(
        id: id,
        title: 'تذكير: $medicationName',
        body: message,
        scheduledDate: scheduledDate,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'medicine_channel',
            'Medicine reminders',
            channelDescription: 'Reminders to take medicines',
            importance: Importance.max,
            priority: Priority.max,
            playSound: true,
            enableVibration: true,
            fullScreenIntent: true,
            visibility: NotificationVisibility.public,
            audioAttributesUsage: AudioAttributesUsage.alarm,
          ),
          iOS: DarwinNotificationDetails(
            sound: 'default.caf',
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } on PlatformException catch (e) {
      if (_isAlarmLimitException(e)) {
        debugPrint('[NotificationService] Alarm limit reached for skipped reminder. Using in-memory timer fallback for id=$id');
        _scheduleTimerFallback(
          id,
          'تذكير: $medicationName',
          message,
          when,
          jsonEncode({
            'prefix': 'skipped_$medicationName',
            'name': medicationName,
            'dose': message,
            'id': id,
            'scheduled': when.millisecondsSinceEpoch,
          }),
        );
      } else {
        rethrow;
      }
    }
    
    debugPrint('[NotificationService] Scheduled motivational reminder for $medicationName in 1 hour');
  }

  /// Show an immediate alert-style notification (used for health warnings)
  Future<void> showAlertNotification({required String title, required String body}) async {
    await init();
    await _ensureDarwinPermissions();

    final id = DateTime.now().millisecondsSinceEpoch & 0x7fffffff;
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'caregiver_alerts',
          'Caregiver Alerts',
          channelDescription: 'Emergency and adherence alerts sent to caregivers',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBanner: true,
          presentList: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }
}