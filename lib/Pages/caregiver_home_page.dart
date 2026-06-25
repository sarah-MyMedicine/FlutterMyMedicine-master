import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../components/footer.dart';
import '../components/medication_list.dart';
import '../providers/medication_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import '../services/patient_data_sync_service.dart';
import '../utils/translations.dart';
import 'adherence_log_page.dart';
import 'appointments_page.dart';
import 'blood_pressure_log.dart';
import 'blood_sugar_log.dart';
import 'caregiver_link_page.dart';
import 'health_report_page.dart';
import 'lab_results_page.dart';
import 'menopause_stage_page.dart';
import 'mother_fetus_care_page.dart';
import 'patient_profile_editor_page.dart';
import 'puberty_stage_page.dart';
import 'symptom_log_page.dart';

class CaregiverHomePage extends StatefulWidget {
  const CaregiverHomePage({super.key});

  @override
  State<CaregiverHomePage> createState() => _CaregiverHomePageState();
}

class _CaregiverHomePageState extends State<CaregiverHomePage>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  List<Map<String, dynamic>> _linkedPatients = <Map<String, dynamic>>[];
  bool _isLoading = true;
  bool _isSwitchingProfile = false;
  int _activeTabIndex = 0;
  bool _isHandlingTabChange = false;
  Timer? _liveRefreshTimer;

  @override
  void initState() {
    super.initState();
    _loadLinkedPatients();
  }

  @override
  void dispose() {
    _liveRefreshTimer?.cancel();
    _tabController?.removeListener(_handleTabChange);
    _tabController?.dispose();
    super.dispose();
  }

  String? _targetUsernameForTab(int index) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (index == 0) return userProvider.username?.trim().toLowerCase();

    final patientIndex = index - 1;
    if (patientIndex < 0 || patientIndex >= _linkedPatients.length) {
      return userProvider.username?.trim().toLowerCase();
    }

    final username = (_linkedPatients[patientIndex]['username'] ?? '').toString().trim().toLowerCase();
    if (username.isEmpty) return userProvider.username?.trim().toLowerCase();
    return username;
  }

  void _configureLiveRefreshForActiveTab() {
    _liveRefreshTimer?.cancel();
    if (_activeTabIndex == 0) return;

    _liveRefreshTimer = Timer.periodic(const Duration(seconds: 20), (_) async {
      if (!mounted || _isHandlingTabChange) return;
      final currentIndex = _tabController?.index ?? 0;
      if (currentIndex != _activeTabIndex) return;

      final username = _targetUsernameForTab(currentIndex);
      if (username == null || username.isEmpty) return;

      try {
        await PatientDataSyncService().syncAfterAuthentication(
          context: context,
          username: username,
        );
      } catch (e) {
        debugPrint('Live refresh failed for $username: $e');
      }
    });
  }

  Future<void> _switchProfileForTab(int index) async {
    if (!mounted) return;
    if (_isHandlingTabChange) return;

    final username = _targetUsernameForTab(index);
    if (username == null || username.isEmpty) return;

    _isHandlingTabChange = true;
    if (mounted) {
      setState(() => _isSwitchingProfile = true);
    }

    try {
      await PatientDataSyncService().syncLocalToCloudIfAuthenticated();
      if (!mounted) return;
      await PatientDataSyncService().syncAfterAuthentication(
        context: context,
        username: username,
      );
      _activeTabIndex = index;
      _configureLiveRefreshForActiveTab();
    } catch (e) {
      debugPrint('Failed to switch profile context to $username: $e');
    } finally {
      _isHandlingTabChange = false;
      if (mounted) {
        setState(() => _isSwitchingProfile = false);
      }
    }
  }

  void _handleTabChange() {
    final controller = _tabController;
    if (controller == null) return;
    if (controller.index == _activeTabIndex) return;
    _switchProfileForTab(controller.index);
  }

  Future<void> _loadLinkedPatients() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final username = userProvider.username;

    if (username == null || username.isEmpty) {
      if (!mounted) return;
      setState(() {
        _linkedPatients = <Map<String, dynamic>>[];
        _tabController = TabController(length: 1, vsync: this);
        _isLoading = false;
      });
      return;
    }

    try {
      final patients = await ApiService().getLinkedPatients(username);
      if (!mounted) return;
      setState(() {
        _linkedPatients = patients;
        _tabController?.dispose();
        _tabController = TabController(length: _linkedPatients.length + 1, vsync: this);
        _tabController?.addListener(_handleTabChange);
        _activeTabIndex = 0;
        _isLoading = false;
      });
      await _switchProfileForTab(0);
    } catch (e) {
      debugPrint('Error loading linked patients: $e');
      if (!mounted) return;
      setState(() {
        _linkedPatients = <Map<String, dynamic>>[];
        _tabController?.dispose();
        _tabController = TabController(length: 1, vsync: this);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final lang = settings.language;

    if (_isLoading || _tabController == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppTranslations.translate('caregiver', lang)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppTranslations.translate('caregiver', lang)),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: <Widget>[
            Tab(text: AppTranslations.translate('my_menu', lang)),
            ..._linkedPatients.map((patient) {
              final username = (patient['username'] ?? '').toString();
              final name = (patient['name'] ?? '').toString();
              final label = name.isNotEmpty
                  ? name
                  : (username.isNotEmpty
                      ? username
                      : AppTranslations.translate('patient', lang));
              return Tab(text: label);
            }),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: <Widget>[
          const _CaregiverPersonalMenuTab(),
          ..._linkedPatients.map((patient) {
            return _PatientMenuTab(patient: patient);
          }),
        ],
      ),
      bottomNavigationBar: const Footer(),
      floatingActionButton: _isSwitchingProfile
          ? const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
    );
  }
}

class _CaregiverPersonalMenuTab extends StatelessWidget {
  const _CaregiverPersonalMenuTab();

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final lang = settings.language;

    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: Column(
              children: <Widget>[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: settings.themeColor.withAlpha(24),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: settings.themeColor.withAlpha(96)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        AppTranslations.translate(
                          'medication_monitor_dashboard',
                          lang,
                        ),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: settings.themeColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppTranslations.translate(
                          'medication_monitor_tabs_hint',
                          lang,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Consumer<MedicationProvider>(
                    builder: (context, medProv, _) {
                      final items = medProv.items;

                      return GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1,
                        children: <Widget>[
                          _MenuTile(
                            icon: Icons.calendar_today,
                            label: AppTranslations.translate('appointments', lang),
                            backgroundImageAsset:
                                'assets/button_backgrounds/Medical_Appointments_button.png',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const AppointmentsPage()),
                            ),
                          ),
                          _MenuTile(
                            icon: Icons.local_pharmacy,
                            label: AppTranslations.translate('my_medications', lang),
                            badge: items.isNotEmpty ? items.length : 0,
                            backgroundImageAsset:
                                'assets/button_backgrounds/my_medications_button.png',
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                builder: (ctx) => SizedBox(
                                  height: MediaQuery.of(ctx).size.height * 0.85,
                                  child: MedicationList(),
                                ),
                              );
                            },
                          ),
                          _MenuTile(
                            icon: Icons.note,
                            label: AppTranslations.translate('adherence_log', lang),
                            backgroundImageAsset:
                                'assets/button_backgrounds/Adherence_Log_button.png',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const AdherenceLogPage()),
                            ),
                          ),
                          _MenuTile(
                            icon: Icons.sentiment_satisfied_alt,
                            label: AppTranslations.translate('symptom_log', lang),
                            backgroundImageAsset:
                                'assets/button_backgrounds/Symptom_Log.png',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const SymptomLogPage()),
                            ),
                          ),
                          _MenuTile(
                            icon: Icons.medical_services,
                            label: AppTranslations.translate('health_report', lang),
                            backgroundImageAsset:
                                'assets/button_backgrounds/Health_Report_button.png',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const HealthReportPage()),
                            ),
                          ),
                          _MenuTile(
                            icon: Icons.vaccines,
                            label: AppTranslations.translate('lab_results', lang),
                            backgroundImageAsset:
                                'assets/button_backgrounds/Lab_results.png',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const LabResultsPage()),
                            ),
                          ),
                          _MenuTile(
                            icon: Icons.access_time,
                            label: AppTranslations.translate('blood_pressure_log', lang),
                            backgroundImageAsset:
                                'assets/button_backgrounds/blood_pressure_button.png',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const BloodPressurePage()),
                            ),
                          ),
                          _MenuTile(
                            icon: Icons.bloodtype,
                            label: AppTranslations.translate('blood_sugar_log', lang),
                            backgroundImageAsset:
                                'assets/button_backgrounds/blood_sugar_button.png',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const BloodSugarPage()),
                            ),
                          ),
                          _CaregiverActionTile(
                            icon: Icons.notifications,
                            label: AppTranslations.translate('notifications', lang),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const CaregiverLinkPage(initialTabIndex: 2),
                              ),
                            ),
                          ),
                          _CaregiverActionTile(
                            icon: Icons.people_alt,
                            label: AppTranslations.translate('linked_patients', lang),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const CaregiverLinkPage(initialTabIndex: 1),
                              ),
                            ),
                          ),
                          _CaregiverActionTile(
                            icon: Icons.people,
                            label: AppTranslations.translate('caregiver_link', lang),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const CaregiverLinkPage(initialTabIndex: 0),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PatientMenuTab extends StatelessWidget {
  final Map<String, dynamic> patient;

  const _PatientMenuTab({required this.patient});

  Color _shiftLightness(Color color, double delta) {
    final hsl = HSLColor.fromColor(color);
    final adjusted = (hsl.lightness + delta).clamp(0.0, 1.0);
    return hsl.withLightness(adjusted).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final lang = settings.language;
    final name = (patient['name'] ?? '').toString();
    final username = (patient['username'] ?? '').toString();
    final patientLabel = name.isNotEmpty
      ? name
      : (username.isNotEmpty ? username : AppTranslations.translate('patient', lang));

    final age = settings.age;
    final isFemale = settings.gender == PatientGender.female;
    final showPubertyStage = age != null && age >= 12 && age <= 17 && isFemale;
    final showMenopauseStage = age != null && age > 48 && isFemale;
    final showMotherFetusCare = age != null && age > 19 && isFemale;

    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: Column(
              children: <Widget>[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: settings.themeColor.withAlpha(24),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: settings.themeColor.withAlpha(96)),
                  ),
                  child: Text(
                    patientLabel,
                    style: TextStyle(
                      color: settings.themeColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => PatientProfileEditorPage(
                            patientUsername: username.isNotEmpty ? username : null,
                            patientDisplayName: patientLabel,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit),
                    label: Text(
                      AppTranslations.translate('edit_profile', lang),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _shiftLightness(settings.themeColor, 0.08),
                        _shiftLightness(settings.themeColor, -0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(color: Colors.black12, blurRadius: 6),
                    ],
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              AppTranslations.translate('pharmacist_consultation', lang),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              AppTranslations.translate('get_info_about_medicines', lang),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.info_outline, color: Colors.white70),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Consumer<MedicationProvider>(
                    builder: (context, medProv, _) {
                      final items = medProv.items;

                      return GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1,
                        children: <Widget>[
                          _MenuTile(
                            icon: Icons.calendar_today,
                            label: AppTranslations.translate('appointments', lang),
                            backgroundImageAsset:
                                'assets/button_backgrounds/Medical_Appointments_button.png',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const AppointmentsPage()),
                            ),
                          ),
                          _MenuTile(
                            icon: Icons.local_pharmacy,
                            label: AppTranslations.translate('my_medications', lang),
                            badge: items.isNotEmpty ? items.length : 0,
                            backgroundImageAsset:
                                'assets/button_backgrounds/my_medications_button.png',
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                builder: (ctx) => SizedBox(
                                  height: MediaQuery.of(ctx).size.height * 0.85,
                                  child: MedicationList(),
                                ),
                              );
                            },
                          ),
                          _MenuTile(
                            icon: Icons.add_alert,
                            label: AppTranslations.translate('emergency', lang),
                            highlight: true,
                            backgroundImageAsset:
                                'assets/button_backgrounds/emergency_button.png',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppTranslations.translate(
                                      'patient_menu_preview_medication_monitor_only',
                                      lang,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          _MenuTile(
                            icon: Icons.note,
                            label: AppTranslations.translate('adherence_log', lang),
                            backgroundImageAsset:
                                'assets/button_backgrounds/Adherence_Log_button.png',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const AdherenceLogPage()),
                            ),
                          ),
                          _MenuTile(
                            icon: Icons.sentiment_satisfied_alt,
                            label: AppTranslations.translate('symptom_log', lang),
                            backgroundImageAsset:
                                'assets/button_backgrounds/Symptom_Log.png',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const SymptomLogPage()),
                            ),
                          ),
                          _MenuTile(
                            icon: Icons.medical_services,
                            label: AppTranslations.translate('health_report', lang),
                            backgroundImageAsset:
                                'assets/button_backgrounds/Health_Report_button.png',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const HealthReportPage()),
                            ),
                          ),
                          _MenuTile(
                            icon: Icons.vaccines,
                            label: AppTranslations.translate('lab_results', lang),
                            backgroundImageAsset: 'assets/button_backgrounds/Lab_results.png',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const LabResultsPage()),
                            ),
                          ),
                          _MenuTile(
                            icon: Icons.access_time,
                            label: AppTranslations.translate('blood_pressure_log', lang),
                            backgroundImageAsset:
                                'assets/button_backgrounds/blood_pressure_button.png',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const BloodPressurePage()),
                            ),
                          ),
                          _MenuTile(
                            icon: Icons.bloodtype,
                            label: AppTranslations.translate('blood_sugar_log', lang),
                            backgroundImageAsset:
                                'assets/button_backgrounds/blood_sugar_button.png',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const BloodSugarPage()),
                            ),
                          ),
                          if (showPubertyStage)
                            _MenuTile(
                              icon: Icons.flutter_dash,
                              label: AppTranslations.translate('puberty_stage', lang),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const PubertyStageInfoPage()),
                              ),
                            ),
                          if (showMenopauseStage)
                            _MenuTile(
                              icon: Icons.spa,
                              label: AppTranslations.translate('menopause_stage_title', lang),
                              backgroundImageAsset:
                                  'assets/button_backgrounds/Menopause_Stage.png',
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const MenopauseStageInfoPage()),
                              ),
                            ),
                          if (showMotherFetusCare)
                            _MenuTile(
                              icon: Icons.pregnant_woman,
                              label: AppTranslations.translate('mother_fetus_care', lang),
                              backgroundImageAsset:
                                  'assets/button_backgrounds/Mother_and_Fetus_care.png',
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const MotherFetusCarePanel()),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CaregiverActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CaregiverActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const <BoxShadow>[BoxShadow(color: Colors.black12, blurRadius: 6)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 30, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final int? badge;
  final bool highlight;
  final VoidCallback? onTap;
  final String? backgroundImageAsset;

  const _MenuTile({
    required this.icon,
    required this.label,
    this.badge,
    this.highlight = false,
    this.onTap,
    this.backgroundImageAsset,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = highlight
      ? (isDark ? Colors.red.shade900.withValues(alpha: 0.28) : Colors.red.shade50)
      : theme.cardColor;
    final hasBackgroundImage =
        backgroundImageAsset != null && backgroundImageAsset!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: hasBackgroundImage ? null : bg,
          image: hasBackgroundImage
              ? DecorationImage(
                  image: AssetImage(backgroundImageAsset!),
                  fit: BoxFit.cover,
                )
              : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.12),
              blurRadius: 6,
            ),
          ],
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withAlpha(20),
          ),
        ),
        child: hasBackgroundImage
            ? Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      Color.fromRGBO(0, 0, 0, 0.15),
                      Color.fromRGBO(0, 0, 0, 0.45),
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(10),
                child: Stack(
                  children: <Widget>[
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          shadows: <Shadow>[
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 5,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if ((badge ?? 0) > 0)
                      Positioned(
                        left: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${badge!}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(icon, color: Theme.of(context).primaryColor),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if ((badge ?? 0) > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${badge!}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
