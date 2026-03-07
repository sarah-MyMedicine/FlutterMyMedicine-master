import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/notification_service.dart';
import '../services/api_service.dart';

class MedicationProvider extends ChangeNotifier {
  static const String _storageKey = 'medications_v1';
  static const String _missedDosesKey = 'missed_doses_tracking';

  // Each item may include an optional imagePath (local file path to a photo)
  // We also store a prefix id so we can cancel scheduled notifications when removing
  final List<Map<String, String?>> _items = [];
  
  // Track consecutive missed doses per medication (by notifPrefix)
  final Map<String, int> _consecutiveMissedDoses = {};
  
  // Track the last expected dose time per medication
  final Map<String, DateTime> _lastExpectedDoseTime = {};
  
  // Track if we've already notified for current missed doses (to avoid spam)
  final Map<String, bool> _hasNotifiedForCurrentMissed = {};

  List<Map<String, String?>> get items => List.unmodifiable(_items);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    if (raw == null || raw.isEmpty) {
      _items.clear();
      notifyListeners();
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        _items
          ..clear()
          ..addAll(
            decoded.whereType<Map>().map((entry) {
              final map = entry.map(
                (key, value) => MapEntry(key.toString(), value?.toString()),
              );

              map.putIfAbsent(
                'notifPrefix',
                () => DateTime.now().microsecondsSinceEpoch.toString(),
              );

              return Map<String, String?>.from(map);
            }),
          );
      }
    } catch (e) {
      debugPrint('[MedicationProvider.load] Failed to parse saved medications: $e');
      _items.clear();
    }
    
    // Load missed doses tracking data
    final missedDosesRaw = prefs.getString(_missedDosesKey);
    if (missedDosesRaw != null && missedDosesRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(missedDosesRaw) as Map<String, dynamic>;
        _consecutiveMissedDoses.clear();
        decoded.forEach((key, value) {
          if (value is int) {
            _consecutiveMissedDoses[key] = value;
          }
        });
      } catch (e) {
        debugPrint('[MedicationProvider.load] Failed to load missed doses tracking: $e');
      }
    }

    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = _items.map((item) => Map<String, String?>.from(item)).toList();
    await prefs.setString(_storageKey, jsonEncode(payload));
  }
  
  Future<void> _saveMissedDosesTracking() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_missedDosesKey, jsonEncode(_consecutiveMissedDoses));
  }

  Future<void> add(String name, String dose, {String? imagePath, int intervalHours = 24, String? startTime, String? startDate, String? chronicDisease}) async {
    final prefix = DateTime.now().millisecondsSinceEpoch.toString();
    debugPrint('[MedicationProvider.add] Adding medication: $name, dose: $dose, interval: $intervalHours hours, startTime: $startTime, startDate: $startDate, chronicDisease: $chronicDisease');

    _items.add({
      'name': name,
      'dose': dose,
      'imagePath': imagePath,
      'intervalHours': intervalHours.toString(),
      'startTime': startTime,
      'startDate': startDate,
      'chronicDisease': chronicDisease,
      'notifPrefix': prefix,
    });

    await _saveToPrefs();

    // Schedule notifications based on startTime, optional startDate and intervalHours
    try {
      if (startTime != null) {
        final parts = startTime.split(':');
        if (parts.length == 2) {
          final h = int.tryParse(parts[0]);
          final m = int.tryParse(parts[1]);
          if (h != null && m != null) {
            DateTime now = DateTime.now();
            debugPrint('[MedicationProvider.add] Parsing time: $h:$m, now=$now');

            DateTime scheduled = DateTime(now.year, now.month, now.day, h, m);
            
            if (startDate != null) {
              try {
                final base = DateTime.parse(startDate);
                scheduled = DateTime(base.year, base.month, base.day, h, m);
                debugPrint('[MedicationProvider.add] Using provided date: $startDate, scheduled: $scheduled');
              } catch (e) {
                debugPrint('[MedicationProvider.add] Failed to parse date, using today: $scheduled, error: $e');
              }
            }

            DateTime firstDue = scheduled;
            // Push forward until it is in the future
            // If the scheduled time is in the past, add interval hours repeatedly until we reach a future time
            while (!firstDue.isAfter(now)) {
              firstDue = firstDue.add(Duration(hours: intervalHours));
              debugPrint('[MedicationProvider.add] Past time detected, advancing to next interval: $firstDue');
            }
            debugPrint('[MedicationProvider.add] First due time: $firstDue, now: $now, diff: ${firstDue.difference(now).inMinutes} minutes');

            // schedule next 30 occurrences starting at the next due time
            debugPrint('[MedicationProvider.add] About to schedule ${intervalHours}h recurring notifications starting at $firstDue');
            await NotificationService().scheduleRepeatedOccurrences(
              prefix: prefix,
              title: 'موعد تناول $name',
              body: '$dose · كل ${intervalHours} ساعة',
              firstOccurrence: firstDue,
              intervalHours: intervalHours,
              occurrences: 30,
            );
            debugPrint('[MedicationProvider.add] Successfully scheduled notifications for prefix: $prefix');
          } else {
            debugPrint('[MedicationProvider.add] Failed to parse hours/minutes from $startTime');
          }
        } else {
          debugPrint('[MedicationProvider.add] Invalid time format: $startTime');
        }
      } else {
        debugPrint('[MedicationProvider.add] No startTime provided, skipping notification scheduling');
      }
    } catch (e, st) {
      debugPrint('[MedicationProvider.add] ERROR scheduling notifications: $e\n$st');
    }

    notifyListeners();
  }

  Future<void> recordTaken(String prefix) async {
    // Find medication
    final idx = _items.indexWhere((it) => it['notifPrefix'] == prefix);
    if (idx == -1) return;

    final item = _items[idx];
    final intervalStr = item['intervalHours'];
    final interval = int.tryParse(intervalStr ?? '24') ?? 24;

    // Cancel existing scheduled notifs and reschedule starting from now+interval
    await NotificationService().cancelForPrefix(prefix);
    final now = DateTime.now();
    final first = now.add(Duration(hours: interval));
    await NotificationService().scheduleRepeatedOccurrences(
      prefix: prefix,
      title: 'موعد تناول ${item['name']}',
      body: '${item['dose']} · كل ${interval} ساعة',
      firstOccurrence: first,
      intervalHours: interval,
      occurrences: 30,
    );

    // Save lastTaken timestamp for UI if desired
    item['lastTaken'] = now.toIso8601String();
    
    // Reset consecutive missed doses counter when dose is taken
    _consecutiveMissedDoses[prefix] = 0;
    _hasNotifiedForCurrentMissed[prefix] = false;
    _lastExpectedDoseTime[prefix] = first;
    
    await _saveToPrefs();
    await _saveMissedDosesTracking();

    notifyListeners();
  }

  Future<void> removeAt(int index) async {
    if (index < 0 || index >= _items.length) return;

    final item = _items[index];
    final prefix = item['notifPrefix'];
    if (prefix != null) {
      await NotificationService().cancelForPrefix(prefix);
    }

    _items.removeAt(index);
    await _saveToPrefs();
    notifyListeners();
  }

  Future<void> updateAt(int index, String name, String dose, {String? imagePath, int intervalHours = 24, String? startTime, String? startDate, String? chronicDisease}) async {
    if (index < 0 || index >= _items.length) return;

    final existing = _items[index];
    _items[index] = {
      'name': name,
      'dose': dose,
      'imagePath': imagePath,
      'intervalHours': intervalHours.toString(),
      'startTime': startTime,
      'startDate': startDate,
      'chronicDisease': chronicDisease,
      'notifPrefix': existing['notifPrefix'],
      'lastTaken': existing['lastTaken'],
    };

    await _saveToPrefs();
    notifyListeners();
  }
  
  /// Check all medications for missed doses and notify caregiver if needed
  /// Returns true if any notifications were sent
  Future<bool> checkForMissedDoses(String? patientUsername) async {
    if (patientUsername == null || patientUsername.isEmpty) {
      debugPrint('[MedicationProvider] No patient username, skipping missed dose check');
      return false;
    }
    
    bool anyNotificationsSent = false;
    final now = DateTime.now();
    
    for (final item in _items) {
      final prefix = item['notifPrefix'];
      if (prefix == null) continue;
      
      final name = item['name'] ?? 'Unknown Medication';
      final intervalStr = item['intervalHours'];
      final interval = int.tryParse(intervalStr ?? '24') ?? 24;
      final lastTakenStr = item['lastTaken'];
      
      // Calculate expected dose time
      DateTime? expectedDoseTime;
      
      if (lastTakenStr != null) {
        // If medication was taken before, next dose is lastTaken + interval
        try {
          final lastTaken = DateTime.parse(lastTakenStr);
          expectedDoseTime = lastTaken.add(Duration(hours: interval));
        } catch (e) {
          debugPrint('[MedicationProvider] Failed to parse lastTaken: $e');
        }
      } else {
        // If never taken, calculate from startTime and startDate
        final startTime = item['startTime'];
        final startDate = item['startDate'];
        
        if (startTime != null) {
          final parts = startTime.split(':');
          if (parts.length == 2) {
            final h = int.tryParse(parts[0]);
            final m = int.tryParse(parts[1]);
            
            if (h != null && m != null) {
              DateTime baseDate = DateTime(now.year, now.month, now.day);
              
              if (startDate != null) {
                try {
                  baseDate = DateTime.parse(startDate);
                } catch (e) {
                  debugPrint('[MedicationProvider] Failed to parse startDate: $e');
                }
              }
              
              expectedDoseTime = DateTime(baseDate.year, baseDate.month, baseDate.day, h, m);
              
              // Find the next expected dose time in the past or near future
              while (expectedDoseTime!.isAfter(now)) {
                expectedDoseTime = expectedDoseTime.subtract(Duration(hours: interval));
              }
              
              // Now advance to the first dose that should have been taken
              while (expectedDoseTime!.isBefore(now.subtract(Duration(hours: interval * 2)))) {
                expectedDoseTime = expectedDoseTime.add(Duration(hours: interval));
              }
            }
          }
        }
      }
      
      if (expectedDoseTime == null) {
        debugPrint('[MedicationProvider] Could not calculate expected dose time for $name');
        continue;
      }
      
      // Check if dose was missed (allowing 1 hour grace period)
      final gracePeriod = Duration(hours: 1);
      final missedThreshold = expectedDoseTime.add(gracePeriod);
      
      if (now.isAfter(missedThreshold)) {
        // Dose was missed!
        final currentMissedCount = _consecutiveMissedDoses[prefix] ?? 0;
        
        // Calculate how many doses were missed
        final hoursSinceMissed = now.difference(expectedDoseTime).inHours;
        final dosesMissed = (hoursSinceMissed / interval).floor();
        
        if (dosesMissed > currentMissedCount) {
          // Update missed count
          _consecutiveMissedDoses[prefix] = dosesMissed;
          await _saveMissedDosesTracking();
          
          debugPrint('[MedicationProvider] $name: $dosesMissed consecutive doses missed');
          
          // Notify caregiver if 2 or more doses missed and we haven't notified yet
          if (dosesMissed >= 2 && _hasNotifiedForCurrentMissed[prefix] != true) {
            try {
              await ApiService().notifyMissedDoses(
                patientUsername: patientUsername,
                consecutiveMissed: dosesMissed,
                medicationName: name,
              );
              
              _hasNotifiedForCurrentMissed[prefix] = true;
              anyNotificationsSent = true;
              
              debugPrint('[MedicationProvider] Notified caregiver about $dosesMissed missed doses for $name');
            } catch (e) {
              debugPrint('[MedicationProvider] Failed to notify caregiver: $e');
            }
          }
        }
      } else {
        // Dose not yet missed, reset counter if it was previously set
        if (_consecutiveMissedDoses.containsKey(prefix) && _consecutiveMissedDoses[prefix]! > 0) {
          debugPrint('[MedicationProvider] Resetting missed counter for $name (dose not yet due)');
        }
      }
      
      // Store last expected dose time for reference
      _lastExpectedDoseTime[prefix] = expectedDoseTime;
    }
    
    return anyNotificationsSent;
  }
  
  /// Get the number of consecutive missed doses for a medication
  int getMissedDosesCount(String prefix) {
    return _consecutiveMissedDoses[prefix] ?? 0;
  }
  
  /// Manually trigger missed dose check (can be called from UI or on app resume)
  Future<void> performMissedDoseCheck(String? patientUsername) async {
    await checkForMissedDoses(patientUsername);
    notifyListeners();
  }
}