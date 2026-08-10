import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mymedicineapp/providers/settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('settings provider stores notification preferences for account-backed sync', () async {
    SharedPreferences.setMockInitialValues({});

    final provider = SettingsProvider();
    await provider.load();

    expect(provider.notificationsEnabled, isTrue);
    expect(provider.pushNotificationsEnabled, isTrue);
    expect(provider.criticalAlertsEnabled, isTrue);

    await provider.setNotificationsEnabled(false);
    await provider.setPushNotificationsEnabled(false);
    await provider.setCriticalAlertsEnabled(true);
    await provider.setNotificationVibrationPattern('long');
    await provider.setNotificationChannel('caregiver');
    await provider.setNotificationMode('urgent');
    await provider.setNotificationReminderLeadTime(30);
    await provider.setNotificationChannels(['caregiver', 'medication']);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('settings_notifications_enabled'), isFalse);
    expect(prefs.getBool('settings_push_notifications_enabled'), isFalse);
    expect(prefs.getBool('settings_critical_alerts_enabled'), isTrue);
    expect(prefs.getString('settings_notification_vibration_pattern'), 'long');
    expect(prefs.getString('settings_notification_channel'), 'caregiver');
    expect(prefs.getString('settings_notification_mode'), 'urgent');
    expect(prefs.getInt('settings_notification_reminder_lead_time'), 30);
    expect(prefs.getStringList('settings_notification_channels'), ['caregiver', 'medication']);

    expect(provider.notificationsEnabled, isFalse);
    expect(provider.notificationVibrationPattern, 'long');
    expect(provider.notificationReminderLeadTime, 30);
  });
}
