import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class MedicationProvider extends ChangeNotifier {
  // Each item may include an optional imagePath (local file path to a photo)
  // We also store a prefix id so we can cancel scheduled notifications when removing
  final List<Map<String, String?>> _items = [];

  List<Map<String, String?>> get items => List.unmodifiable(_items);

  void add(String name, String dose, {String? imagePath, int intervalHours = 24, String? startTime, String? startDate}) async {
    final prefix = DateTime.now().millisecondsSinceEpoch.toString();
    debugPrint('[MedicationProvider.add] Adding medication: $name, dose: $dose, interval: $intervalHours hours, startTime: $startTime, startDate: $startDate');

    _items.add({
      'name': name,
      'dose': dose,
      'imagePath': imagePath,
      'intervalHours': intervalHours.toString(),
      'startTime': startTime,
      'startDate': startDate,
      'notifPrefix': prefix,
    });

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

    notifyListeners();
  }

  void removeAt(int index) async {
    final item = _items[index];
    final prefix = item['notifPrefix'];
    if (prefix != null) {
      await NotificationService().cancelForPrefix(prefix);
    }

    _items.removeAt(index);
    notifyListeners();
  }

  void updateAt(int index, String name, String dose, {String? imagePath, int intervalHours = 24, String? startTime, String? startDate}) {
    _items[index] = {'name': name, 'dose': dose, 'imagePath': imagePath, 'intervalHours': intervalHours.toString(), 'startTime': startTime, 'startDate': startDate};
    notifyListeners();
  }
}