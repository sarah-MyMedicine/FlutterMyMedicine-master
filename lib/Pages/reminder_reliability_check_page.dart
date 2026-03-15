import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../services/notification_service.dart';
import '../utils/translations.dart';

class ReminderReliabilityCheckPage extends StatefulWidget {
  const ReminderReliabilityCheckPage({super.key});

  @override
  State<ReminderReliabilityCheckPage> createState() =>
      _ReminderReliabilityCheckPageState();
}

class _ReminderReliabilityCheckPageState
    extends State<ReminderReliabilityCheckPage> {
  bool _isChecking = false;
  bool? _notificationsEnabled;
  bool? _exactAlarmsEnabled;
  String? _error;

  bool _batteryUnrestricted = false;
  bool _autostartEnabled = false;
  bool _lockScreenAllowed = false;

  @override
  void initState() {
    super.initState();
    _runCheck();
  }

  Future<void> _runCheck() async {
    setState(() {
      _isChecking = true;
      _error = null;
    });

    try {
      final status = await NotificationService().getReminderReliabilityStatus();
      setState(() {
        _notificationsEnabled = status['notificationsEnabled'];
        _exactAlarmsEnabled = status['exactAlarmsEnabled'];
      });
    } catch (_) {
      setState(() {
        _error = 'reminder_check_failed';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  Future<void> _enableNotifications() async {
    await NotificationService().requestNotificationsPermission();
    await _runCheck();
  }

  Future<void> _enableExactAlarms() async {
    await NotificationService().requestExactAlarmPermission();
    await _runCheck();
  }

  Future<void> _sendTestReminder(String lang) async {
    await NotificationService().sendTestNotification();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppTranslations.translate('test_reminder_sent', lang)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, sp, _) {
        final lang = sp.language;
        final technicalReady =
            (_notificationsEnabled != false) && (_exactAlarmsEnabled != false);
        final manualReady =
            _batteryUnrestricted && _autostartEnabled && _lockScreenAllowed;
        final allReady = technicalReady && manualReady;

        return Directionality(
          textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                AppTranslations.translate('reminder_reliability_check', lang),
              ),
            ),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  AppTranslations.translate(
                    'reminder_reliability_check_desc',
                    lang,
                  ),
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 12),
                if (_isChecking) const LinearProgressIndicator(),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    AppTranslations.translate(_error!, lang),
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
                const SizedBox(height: 16),
                _buildStatusTile(
                  context: context,
                  lang: lang,
                  titleKey: 'notification_permission',
                  status: _notificationsEnabled,
                  onFix: _enableNotifications,
                  fixLabelKey: 'enable_notifications',
                ),
                const SizedBox(height: 10),
                _buildStatusTile(
                  context: context,
                  lang: lang,
                  titleKey: 'exact_alarm_permission',
                  status: _exactAlarmsEnabled,
                  onFix: _enableExactAlarms,
                  fixLabelKey: 'enable_exact_alarms',
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _isChecking ? null : _runCheck,
                  icon: const Icon(Icons.refresh),
                  label: Text(
                    AppTranslations.translate('run_reliability_check', lang),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _sendTestReminder(lang),
                  icon: const Icon(Icons.notifications_active_outlined),
                  label: Text(
                    AppTranslations.translate('send_test_reminder', lang),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  AppTranslations.translate('manual_reliability_checks', lang),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                CheckboxListTile(
                  value: _batteryUnrestricted,
                  onChanged: (value) {
                    setState(() {
                      _batteryUnrestricted = value ?? false;
                    });
                  },
                  title: Text(
                    AppTranslations.translate('battery_unrestricted', lang),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  value: _autostartEnabled,
                  onChanged: (value) {
                    setState(() {
                      _autostartEnabled = value ?? false;
                    });
                  },
                  title: Text(
                    AppTranslations.translate('autostart_enabled', lang),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  value: _lockScreenAllowed,
                  onChanged: (value) {
                    setState(() {
                      _lockScreenAllowed = value ?? false;
                    });
                  },
                  title: Text(
                    AppTranslations.translate('lock_screen_allowed', lang),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: allReady
                        ? Colors.green.withOpacity(0.12)
                        : Colors.orange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        allReady ? Icons.check_circle : Icons.warning_amber_rounded,
                        color: allReady ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppTranslations.translate(
                            allReady
                                ? 'reliability_ready'
                                : 'reliability_needs_attention',
                            lang,
                          ),
                        ),
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

  Widget _buildStatusTile({
    required BuildContext context,
    required String lang,
    required String titleKey,
    required bool? status,
    required Future<void> Function() onFix,
    required String fixLabelKey,
  }) {
    final isOk = status == true;
    final isFailed = status == false;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOk
              ? Colors.green.withOpacity(0.4)
              : isFailed
              ? Colors.red.withOpacity(0.4)
              : Colors.grey.withOpacity(0.4),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isOk
                    ? Icons.check_circle
                    : isFailed
                    ? Icons.error_outline
                    : Icons.help_outline,
                color: isOk
                    ? Colors.green
                    : isFailed
                    ? Colors.red
                    : Colors.grey,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppTranslations.translate(titleKey, lang),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                AppTranslations.translate(
                  isOk
                      ? 'status_ok'
                      : isFailed
                      ? 'status_off'
                      : 'status_unknown',
                  lang,
                ),
              ),
            ],
          ),
          if (isFailed) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onFix,
                icon: const Icon(Icons.settings),
                label: Text(AppTranslations.translate(fixLabelKey, lang)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
