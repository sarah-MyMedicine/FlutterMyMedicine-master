import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/adherence_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/translations.dart';

class MedicationItem extends StatelessWidget {
  final String name;
  final String dose;
  final String? imagePath;
  final String? intervalHours;
  final String? startTime;
  final String? startDate;
  final String? chronicDisease;
  final int missedDosesCount;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const MedicationItem({
    super.key,
    required this.name,
    required this.dose,
    this.imagePath,
    this.intervalHours,
    this.startTime,
    this.startDate,
    this.chronicDisease,
    this.missedDosesCount = 0,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  String _getFrequencyText(String lang) {
    final hours = int.tryParse(intervalHours ?? '24') ?? 24;
    
    if (hours <= 24) {
      if (hours == 1) return AppTranslations.translate('every_hour', lang);
      if (hours == 2) return AppTranslations.translate('every_2_hours', lang);
      if (hours == 3) return AppTranslations.translate('every_3_hours', lang);
      if (hours == 4) return AppTranslations.translate('every_4_hours', lang);
      if (hours == 6) return AppTranslations.translate('every_6_hours', lang);
      if (hours == 8) return AppTranslations.translate('every_8_hours', lang);
      if (hours == 12) return AppTranslations.translate('twice_per_day', lang);
      if (hours == 24) return AppTranslations.translate('once_per_day', lang);
      return '${AppTranslations.translate('every_x_hours', lang)} $hours ${AppTranslations.translate('per_hour', lang)}';
    } else if (hours >= 84 && hours <= 168) {
      final timesPerWeek = (168 / hours).round();
      if (timesPerWeek == 1) return AppTranslations.translate('once_per_week', lang);
      if (timesPerWeek == 2) return AppTranslations.translate('twice_per_week', lang);
      return '$timesPerWeek ${AppTranslations.translate('times_per_week', lang)}';
    } else if (hours >= 180) {
      final timesPerMonth = (720 / hours).round();
      if (timesPerMonth == 1) return AppTranslations.translate('once_per_month', lang);
      if (timesPerMonth == 2) return AppTranslations.translate('twice_per_month', lang);
      return '$timesPerMonth ${AppTranslations.translate('times_per_month', lang)}';
    }
    return '${AppTranslations.translate('every_x_hours', lang)} $hours ${AppTranslations.translate('per_hour', lang)}';
  }

  String _getMedicationTypeText(String lang) {
    if (chronicDisease == 'ارتفاع ضغط الدم') return AppTranslations.translate('bp_medication', lang);
    if (chronicDisease == 'السكري') return AppTranslations.translate('bs_medication', lang);
    return chronicDisease ?? '';
  }

  IconData _getMedicationTypeIcon() {
    if (chronicDisease == 'ارتفاع ضغط الدم') return Icons.favorite;
    if (chronicDisease == 'السكري') return Icons.water_drop;
    return Icons.medical_information;
  }

  Color _getMedicationTypeColor() {
    if (chronicDisease == 'ارتفاع ضغط الدم') return Colors.red;
    if (chronicDisease == 'السكري') return Colors.orange;
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, sp, child) {
        final lang = sp.language;
        
        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 8, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: imagePath != null
                        ? ClipOval(
                            child: Builder(
                              builder: (context) {
                                final file = File(imagePath!);
                                if (file.existsSync()) {
                                  try {
                                    return Image.file(
                                      file,
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                      cacheWidth: 80,
                                      cacheHeight: 80,
                                    );
                                  } catch (e) {
                                    // If loading fails, show default icon
                                    return CircleAvatar(
                                      backgroundColor: Theme.of(context).colorScheme.secondary.withAlpha(38),
                                      child: Icon(
                                        Icons.medication,
                                        color: Theme.of(context).colorScheme.secondary,
                                      ),
                                    );
                                  }
                                } else {
                                  // If file does not exist, show default icon
                                  return CircleAvatar(
                                    backgroundColor: Theme.of(context).colorScheme.secondary.withAlpha(38),
                                    child: Icon(
                                      Icons.medication,
                                      color: Theme.of(context).colorScheme.secondary,
                                    ),
                                  );
                                }
                              },
                            ),
                          )
                        : CircleAvatar(
                            backgroundColor:
                                Theme.of(context).colorScheme.secondary.withAlpha(38),
                            child: Icon(
                              Icons.medication,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Consumer<AdherenceProvider>(
                      builder: (context, adherenceProvider, child) {
                        final intervalHrs = int.tryParse(intervalHours ?? '24') ?? 24;
                        DateTime? medStartDate;
                        if (startDate != null) {
                          try {
                            medStartDate = DateTime.parse(startDate!);
                          } catch (e) {
                            medStartDate = null;
                          }
                        }

                        final adherenceScore = adherenceProvider.calculateMedicationAdherence(
                          medicationName: name,
                          intervalHours: intervalHrs,
                          dose: dose,
                          startDate: medStartDate,
                          daysToCheck: 30,
                        );

                        Color? scoreColor;
                        IconData? scoreIcon;
                        if (adherenceScore != null) {
                          if (adherenceScore >= 80) {
                            scoreColor = Colors.green[700];
                            scoreIcon = Icons.check_circle;
                          } else if (adherenceScore >= 60) {
                            scoreColor = Colors.orange[700];
                            scoreIcon = Icons.warning;
                          } else {
                            scoreColor = Colors.red[700];
                            scoreIcon = Icons.error;
                          }
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 2),
                            Text(
                              '$dose · ${_getFrequencyText(lang)}${startTime != null ? ' · $startTime' : ''}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            if (chronicDisease != null && chronicDisease!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Row(
                                  children: [
                                    Icon(_getMedicationTypeIcon(), size: 14, color: _getMedicationTypeColor()),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        _getMedicationTypeText(lang),
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: _getMedicationTypeColor().withOpacity(0.8),
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (missedDosesCount > 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Row(
                                  children: [
                                    Icon(Icons.notifications_active, size: 14, color: Colors.red[700]),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        missedDosesCount == 1
                                            ? AppTranslations.translate('missed_dose', lang)
                                            : '${AppTranslations.translate('missed_doses', lang)}: $missedDosesCount',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Colors.red[700],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Row(
                                children: [
                                  Icon(
                                    adherenceScore == null ? Icons.hourglass_top : scoreIcon,
                                    size: 14,
                                    color: adherenceScore == null ? Colors.grey[700] : scoreColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      adherenceScore == null
                                          ? AppTranslations.translate('adherence_waiting_first_dose', lang)
                                          : '${AppTranslations.translate('adherence', lang)}: ${adherenceScore.toStringAsFixed(0)}%',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: adherenceScore == null ? Colors.grey[700] : scoreColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit?.call();
                      } else if (value == 'delete') {
                        onDelete?.call();
                      }
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(Icons.edit, size: 18),
                            const SizedBox(width: 12),
                            Text(AppTranslations.translate('edit', lang)),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete, size: 18, color: Colors.red),
                            const SizedBox(width: 12),
                            Text(AppTranslations.translate('delete', lang), style: const TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
