import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../utils/translations.dart';

class MedicationInfoModal extends StatelessWidget {
  final String name;
  final String dose;
  final String? imagePath;
  final int intervalHours;
  final String? startTime;
  final String? startDate;
  final String? doctorName;
  final String? doctorSpecialty;

  const MedicationInfoModal({
    super.key,
    required this.name,
    required this.dose,
    this.imagePath,
    this.intervalHours = 24,
    this.startTime,
    this.startDate,
    this.doctorName,
    this.doctorSpecialty,
  });


  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, sp, child) {
        final lang = sp.language;
        final assignedDoctorName = (doctorName ?? '').trim();
        final assignedDoctorSpecialty = (doctorSpecialty ?? '').trim();
        final hasDoctorAssignment =
            assignedDoctorName.isNotEmpty || assignedDoctorSpecialty.isNotEmpty;
        
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (imagePath != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Image.file(File(imagePath!), height: 120, fit: BoxFit.cover),
                  ),
                Text(
                  name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('${AppTranslations.translate('dose_label', lang)}: $dose'),
                const SizedBox(height: 4),
                Text('${AppTranslations.translate('interval', lang)}: ${AppTranslations.translate('every_x_hours', lang)} $intervalHours ${AppTranslations.translate('per_hour', lang)}'),
                const SizedBox(height: 4),
                if (startTime != null && startDate != null) 
                  Text('${AppTranslations.translate('first_dose', lang)}: $startDate $startTime'),
                if (startTime != null && startDate == null) 
                  Text('${AppTranslations.translate('first_dose', lang)}: $startTime'),
                if (hasDoctorAssignment) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${AppTranslations.translate('doctor_name', lang)}: '
                    '${assignedDoctorName.isNotEmpty ? assignedDoctorName : '-'}',
                  ),
                  if (assignedDoctorSpecialty.isNotEmpty)
                    Text(
                      '${AppTranslations.translate('specialty', lang)}: $assignedDoctorSpecialty',
                    ),
                ],
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(AppTranslations.translate('close', lang)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
