import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/medication_provider.dart';
import '../providers/adherence_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/user_provider.dart';
import '../components/header.dart';
import '../components/footer.dart';
import '../components/medication_list.dart';
import '../services/api_service.dart';
import '../utils/translations.dart';
import 'blood_pressure_log.dart';
import 'blood_sugar_log.dart';
import 'symptom_log_page.dart';
import 'appointments_page.dart';
import 'adherence_log_page.dart';
import 'puberty_stage_page.dart';
import 'menopause_stage_page.dart';
import 'mother_fetus_care_page.dart';
import 'health_report_page.dart';
import 'lab_results_page.dart';

class _RankPresentation {
  final Color startColor;
  final Color endColor;
  final IconData icon;

  const _RankPresentation({
    required this.startColor,
    required this.endColor,
    required this.icon,
  });
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  _RankPresentation _rankPresentation(MedicationRankStatus status) {
    final rank = status.currentTier?.title;
    if (rank == 'الذيب') {
      return const _RankPresentation(
        startColor: Color(0xFF455A64),
        endColor: Color(0xFF78909C),
        icon: Icons.bolt,
      );
    }
    if (rank == 'السبع') {
      return const _RankPresentation(
        startColor: Color(0xFF1565C0),
        endColor: Color(0xFF42A5F5),
        icon: Icons.local_fire_department,
      );
    }
    if (rank == 'المعدّل') {
      return const _RankPresentation(
        startColor: Color(0xFF00695C),
        endColor: Color(0xFF26A69A),
        icon: Icons.verified,
      );
    }
    return const _RankPresentation(
      startColor: Color(0xFF546E7A),
      endColor: Color(0xFF90A4AE),
      icon: Icons.flag,
    );
  }

  Future<void> _handleEmergencyTap(BuildContext context, String lang) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    if (!userProvider.isPatient) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppTranslations.translate('emergency_patient_only', lang)),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final patientUsername = userProvider.username;
    if (patientUsername == null || patientUsername.isEmpty) return;

    final shouldSend = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppTranslations.translate('send_siren_alert', lang)),
        content: Text(AppTranslations.translate('send_siren_alert_desc', lang)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(AppTranslations.translate('cancel', lang)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(AppTranslations.translate('send_alert', lang)),
          ),
        ],
      ),
    );

    if (shouldSend != true) return;

    try {
      final response = await ApiService().sendEmergencyAlert(
        patientUsername: patientUsername,
        classification: 'siren',
        message: AppTranslations.translate('siren_alert_message', lang),
      );

      final caregiverName = (response['caregiver'] as Map<String, dynamic>?)?['name']?.toString();
      final successMessage = caregiverName != null && caregiverName.isNotEmpty
          ? '${AppTranslations.translate('emergency_alert_sent_to', lang)} $caregiverName'
          : AppTranslations.translate('emergency_alert_sent', lang);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      final raw = e.toString().replaceFirst('Exception: ', '').trim();
      final msg = raw.contains('No linked caregiver')
          ? AppTranslations.translate('no_linked_caregiver', lang)
          : AppTranslations.translate('emergency_alert_failed', lang);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Header(),
            // Center column constrained to a reasonable width to match the design
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 16.0,
                  ),
                  child: Column(
                    children: [
                      // Top info banner (green)
                      // Grid of square tiles (3 columns) using Arabic RTL layout
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: Consumer<SettingsProvider>(
                          builder: (context, settings, _) {
                            // Check if age is between 12-17 and gender is female for puberty stage
                            final age = settings.age;
                            final isFemale =
                                settings.gender == PatientGender.female;
                            final showPubertyStage =
                                age != null &&
                                age >= 12 &&
                                age <= 17 &&
                                isFemale;
                            final showMenopauseStage =
                                age != null && age > 48 && isFemale;
                            final showMotherFetusCare =
                                age != null && age > 19 && isFemale;
                            
                            final lang = settings.language;

                            // Build the grid children list
                            final List<Widget> gridChildren = [
                              _SquareTile(
                                icon: Icons.calendar_today,
                                label: AppTranslations.translate('appointments', lang),
                                backgroundImageAsset:
                                    'assets/button_backgrounds/Medical_Appointments_button.png',
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const AppointmentsPage(),
                                  ),
                                ),
                              ),
                              // My medicines tile (shows count)
                              Consumer<MedicationProvider>(
                                builder: (context, medProv, _) {
                                  final items = medProv.items;
                                  return _SquareTile(
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
                                          height:
                                              MediaQuery.of(ctx).size.height *
                                              0.85,
                                          child: MedicationList(),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                              _SquareTile(
                                icon: Icons.add_alert,
                                label: AppTranslations.translate('emergency', lang),
                                highlight: true,
                                backgroundImageAsset:
                                    'assets/button_backgrounds/emergency_button.png',
                                onTap: () => _handleEmergencyTap(context, lang),
                              ),

                              _SquareTile(
                                icon: Icons.note,
                                label: AppTranslations.translate('adherence_log', lang),
                                backgroundImageAsset:
                                    'assets/button_backgrounds/Adherence_Log_button.png',
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const AdherenceLogPage(),
                                    ),
                                  );
                                },
                              ),
                              _SquareTile(
                                icon: Icons.sentiment_satisfied_alt,
                                label: AppTranslations.translate('symptom_log', lang),
                                backgroundImageAsset:
                                    'assets/button_backgrounds/Symptom_Log.png',
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const SymptomLogPage(),
                                  ),
                                ),
                              ),
                              _SquareTile(
                                icon: Icons.medical_services,
                                label: AppTranslations.translate('health_report', lang),
                                backgroundImageAsset:
                                    'assets/button_backgrounds/Health_Report_button.png',
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const HealthReportPage(),
                                    ),
                                  );
                                },
                              ),

                              _SquareTile(
                                icon: Icons.vaccines,
                                label: AppTranslations.translate('lab_results', lang),
                                backgroundImageAsset:
                                    'assets/button_backgrounds/Lab_results.png',
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const LabResultsPage(),
                                    ),
                                  );
                                },
                              ),
                              _SquareTile(
                                icon: Icons.access_time,
                                label: AppTranslations.translate('blood_pressure_log', lang),
                                backgroundImageAsset:
                                    'assets/button_backgrounds/blood_pressure_button.png',
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const BloodPressurePage(),
                                    ),
                                  );
                                },
                              ),
                              _SquareTile(
                                icon: Icons.bloodtype,
                                label: AppTranslations.translate('blood_sugar_log', lang),
                                backgroundImageAsset:
                                    'assets/button_backgrounds/blood_sugar_button.png',
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const BloodSugarPage(),
                                    ),
                                  );
                                },
                              ),

                              // Conditional puberty stage tile
                              if (showPubertyStage)
                                _SquareTile(
                                  icon: Icons.flutter_dash,
                                  label: AppTranslations.translate('puberty_stage', lang),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const PubertyStageInfoPage(),
                                      ),
                                    );
                                  },
                                ),

                              // Conditional menopause stage tile
                              if (showMenopauseStage)
                                _SquareTile(
                                  icon: Icons.spa,
                                  label: AppTranslations.translate('menopause_stage_title', lang),
                                  backgroundImageAsset:
                                      'assets/button_backgrounds/Menopause_Stage.png',
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const MenopauseStageInfoPage(),
                                      ),
                                    );
                                  },
                                ),

                              // Conditional mother and fetus care tile
                              if (showMotherFetusCare)
                                _SquareTile(
                                  icon: Icons.pregnant_woman,
                                  label: AppTranslations.translate('mother_fetus_care', lang),
                                  backgroundImageAsset:
                                      'assets/button_backgrounds/Mother_and_Fetus_care.png',
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const MotherFetusCarePanel(),
                                      ),
                                    );
                                  },
                                ),

                            ];

                            return GridView.count(
                              crossAxisCount: 3,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 1,
                              children: gridChildren,
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 20),
                      
                      // Overall Adherence Score Card
                      Consumer2<MedicationProvider, AdherenceProvider>(
                        builder: (context, medProvider, adherenceProvider, _) {
                          final medications = medProvider.items;
                          
                          // Only show if there are medications
                          if (medications.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          
                          // Prepare medication data for calculation
                          final medData = medications.map((item) {
                            DateTime? startDate;
                            if (item['startDate'] != null) {
                              try {
                                startDate = DateTime.parse(item['startDate']!);
                              } catch (e) {
                                startDate = null;
                              }
                            }
                            
                            return {
                              'name': item['name'] ?? '',
                              'dose': item['dose'] ?? '',
                              'intervalHours': int.tryParse(item['intervalHours'] ?? '24') ?? 24,
                              'startDate': startDate,
                            };
                          }).toList();
                          
                          // Calculate overall adherence
                          final overallScore = adherenceProvider.calculateOverallAdherence(medData, daysToCheck: 30);

                          if (overallScore == null) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.blueGrey.withOpacity(0.8),
                                    Colors.blueGrey.withOpacity(0.6)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.hourglass_top,
                                    size: 48,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'نسبة الالتزام بالأدوية',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'سيبدأ حساب الالتزام بعد تسجيل أول جرعة',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      Text(
                                        '--',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 32,
                                        ),
                                      ),
                                      Text(
                                        'آخر 30 يوم',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }
                          
                          // Determine color based on score
                          Color scoreColor;
                          IconData scoreIcon;
                          String scoreMessage;
                          if (overallScore >= 80) {
                            scoreColor = Colors.green;
                            scoreIcon = Icons.check_circle;
                            scoreMessage = 'ممتاز! استمر في الالتزام';
                          } else if (overallScore >= 60) {
                            scoreColor = Colors.orange;
                            scoreIcon = Icons.warning;
                            scoreMessage = 'جيد، يمكنك تحسين الالتزام';
                          } else {
                            scoreColor = Colors.red;
                            scoreIcon = Icons.error;
                            scoreMessage = 'يحتاج لتحسين';
                          }
                          
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  scoreColor.withOpacity(0.8),
                                  scoreColor.withOpacity(0.6)
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  scoreIcon,
                                  size: 48,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'نسبة الالتزام بالأدوية',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        scoreMessage,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    Text(
                                      '${overallScore.toStringAsFixed(0)}%',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 32,
                                      ),
                                    ),
                                    const Text(
                                      'آخر 30 يوم',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      Consumer3<MedicationProvider, AdherenceProvider, SettingsProvider>(
                        builder: (context, medProvider, adherenceProvider, settings, _) {
                          final medications = medProvider.items;
                          if (medications.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          final rankStatus = adherenceProvider.calculateRankStatus(
                            medications
                                .map(
                                  (item) => <String, dynamic>{
                                    'name': item['name'] ?? '',
                                    'dose': item['dose'] ?? '',
                                    'intervalHours': item['intervalHours'] ?? '24',
                                    'startDate': item['startDate'],
                                    'startTime': item['startTime'],
                                  },
                                )
                                .toList(),
                          );
                          final rankTheme = _rankPresentation(rankStatus);
                          final lang = settings.language;

                          String helperText;
                          if (rankStatus.isHighestRank) {
                            helperText = AppTranslations.translate(
                              'medication_rank_highest',
                              lang,
                            );
                          } else if (rankStatus.nextTier != null) {
                            final remainingDays =
                                rankStatus.nextTier!.requiredDays - rankStatus.streakDays;
                            helperText =
                                '${AppTranslations.translate('medication_rank_next', lang)} ${rankStatus.nextTier!.title} · $remainingDays ${AppTranslations.translate('days', lang)}';
                          } else {
                            helperText = AppTranslations.translate(
                              'medication_rank_start',
                              lang,
                            );
                          }

                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  rankTheme.startColor,
                                  rankTheme.endColor,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: const [
                                BoxShadow(color: Colors.black12, blurRadius: 8),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.16),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    rankTheme.icon,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppTranslations.translate(
                                          'medication_rank_title',
                                          lang,
                                        ),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        rankStatus.currentTier?.title ??
                                            AppTranslations.translate(
                                              'medication_rank_unranked',
                                              lang,
                                            ),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 26,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        helperText,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${rankStatus.streakDays}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      AppTranslations.translate(
                                        'medication_rank_streak',
                                        lang,
                                      ),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 28),
                      // A short summary card or other content can go here
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const Footer(),
    );
  }
}

// Small square tile used on the home grid
class _SquareTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final int? badge;
  final bool highlight;
  final VoidCallback? onTap;
  final String? backgroundImageAsset;

  const _SquareTile({
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.12),
              blurRadius: 6,
            ),
          ],
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.08),
          ),
        ),
        child: hasBackgroundImage
            ? Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.15),
                      Colors.black.withOpacity(0.45),
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(10),
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Text(
                        label,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          shadows: const [
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$badge',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      children: [
                        const SizedBox(width: 52, height: 52),
                        if ((badge ?? 0) > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$badge',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Center(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
