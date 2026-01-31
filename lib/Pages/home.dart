import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/medication_provider.dart';
import '../providers/settings_provider.dart';
import '../components/header.dart';
import '../components/footer.dart';
import '../components/medication_list.dart';
import '../components/ad_banner.dart';
import '../components/medication_form_modal.dart';
import 'blood_pressure_log.dart';
import 'blood_sugar_log.dart';
import 'symptom_log_page.dart';
import 'appointments_page.dart';
import 'adherence_log_page.dart';
import 'puberty_stage_page.dart';
import 'menopause_stage_page.dart';
import 'mother_fetus_care_page.dart';
import 'health_report_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1EBEA6), Color(0xFF05B3A7)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: Colors.black12, blurRadius: 6),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'استشارة صيدلي',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'مراجعة شاملة لملفك الطبي وعقاراتك على يد صيادلة متخصصين لضمان علاج آمن وفعال',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.info_outline,
                              color: Colors.white70,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

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

                            // Build the grid children list
                            final List<Widget> gridChildren = [
                              _SquareTile(
                                icon: Icons.calendar_today,
                                label: 'مواعيدي الطبية',
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
                                    label: 'أدويتي',
                                    badge: items.isNotEmpty ? items.length : 0,
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
                                label: 'طوارئ',
                                highlight: true,
                                onTap: () {},
                              ),

                              _SquareTile(
                                icon: Icons.note,
                                label: 'سجل الالتزام',
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
                                label: 'سجل الأعراض',
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const SymptomLogPage(),
                                  ),
                                ),
                              ),
                              _SquareTile(
                                icon: Icons.medical_services,
                                label: 'تقرير صحي',
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
                                label: 'نتائج المختبر',
                                onTap: () {},
                              ),
                              _SquareTile(
                                icon: Icons.access_time,
                                label: 'سجل الضغط',
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
                                label: 'سجل السكر',
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
                                  label: 'مرحلة البلوغ',
                                  iconColor: const Color(0xFFD81B60),
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
                                  label: 'مرحلة سن الأمل',
                                  iconColor: const Color(0xFF9C27B0),
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
                                  label: 'رعاية الأم والجنين',
                                  iconColor: const Color(0xFFE91E7A),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const MotherFetusCarePanel(),
                                      ),
                                    );
                                  },
                                ),

                              // Dynamic empty tiles based on conditional buttons
                              if (!showPubertyStage &&
                                  !showMenopauseStage &&
                                  !showMotherFetusCare)
                                _SquareTile(
                                  icon: Icons.more_horiz,
                                  label: '',
                                  onTap: () {},
                                  empty: true,
                                ),
                              if ((!showPubertyStage && !showMenopauseStage) ||
                                  (!showPubertyStage && !showMotherFetusCare) ||
                                  (!showMenopauseStage && !showMotherFetusCare))
                                _SquareTile(
                                  icon: Icons.more_horiz,
                                  label: '',
                                  onTap: () {},
                                  empty: true,
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

                      const SizedBox(height: 28),
                      // A short summary card or other content can go here
                      const AdBanner(),
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
      floatingActionButton: Builder(
        builder: (ctx) {
          assert(() {
            return true;
          }());
          return FloatingActionButton(
            heroTag: 'add_med',
            onPressed: () {
              // Open add modal (same as footer +)
              showModalBottomSheet(
                context: ctx,
                isScrollControlled: true,
                builder: (_) => MedicationFormModal(
                  onSave:
                      (
                        name,
                        dose, {
                        imagePath,
                        intervalHours,
                        startTime,
                        startDate,
                      }) {
                        Provider.of<MedicationProvider>(ctx, listen: false).add(
                          name,
                          dose,
                          imagePath: imagePath,
                          intervalHours: intervalHours ?? 24,
                          startTime: startTime,
                          startDate: startDate,
                        );
                      },
                ),
              );
            },
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: const Icon(Icons.add),
          );
        },
      ),
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
  final bool empty;
  final Color? iconColor;

  const _SquareTile({
    required this.icon,
    required this.label,
    this.badge,
    this.highlight = false,
    this.onTap,
    this.empty = false,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    if (empty) return Container();

    final bg = highlight ? Colors.red.shade50 : Colors.white;
    final defaultIconColor = highlight ? Colors.white : const Color(0xFF36BBA0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
          border: Border.all(color: Colors.grey.withOpacity(0.08)),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: highlight
                      ? Colors.redAccent
                      : const Color(0xFFF6F7FA),
                  child: Icon(icon, color: iconColor ?? defaultIconColor),
                ),
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
            Text(
              label,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
