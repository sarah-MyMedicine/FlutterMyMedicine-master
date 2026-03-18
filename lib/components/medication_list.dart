import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/medication_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/translations.dart';
import 'medication_item.dart';
import 'medication_info_modal.dart';
import 'medication_form_modal.dart';

class MedicationList extends StatelessWidget {
  const MedicationList({super.key});

  void _showInfo(BuildContext context, Map<String, String?> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => MedicationInfoModal(
        name: item['name'] ?? '',
        dose: item['dose'] ?? '',
        imagePath: item['imagePath'],
        intervalHours: int.tryParse(item['intervalHours'] ?? '') ?? 24,
        startTime: item['startTime'],
        startDate: item['startDate'],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, sp, child) {
        final lang = sp.language;
        final provider = Provider.of<MedicationProvider>(context);
        final items = provider.items;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppTranslations.translate('medications_list', lang),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  )
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final item = items[i];
                  final notifPrefix = item['notifPrefix'] ?? '';
                  final missedCount = provider.getMissedDosesCount(notifPrefix);
                  
                  return MedicationItem(
                    name: item['name'] ?? '',
                    dose: item['dose'] ?? '',
                    imagePath: item['imagePath'],
                    intervalHours: item['intervalHours'],
                    startTime: item['startTime'],
                    startDate: item['startDate'],
                    chronicDisease: item['chronicDisease'],
                    missedDosesCount: missedCount,
                    onTap: () => _showInfo(context, item),
                    onEdit: () {
                      Navigator.pop(context);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => MedicationFormModal(
                          initialName: item['name'],
                          initialDose: item['dose'],
                          initialImagePath: item['imagePath'],
                          initialIntervalHours: int.tryParse(item['intervalHours'] ?? '24') ?? 24,
                          initialStartTime: item['startTime'],
                          initialStartDate: item['startDate'],
                          initialChronicDisease: item['chronicDisease'],
                          initialDoctorName: item['doctorName'],
                          initialDoctorSpecialty: item['doctorSpecialty'],
                          onSave: (
                            name,
                            dose, {
                            imagePath,
                            intervalHours,
                            startTime,
                            startDate,
                            chronicDisease,
                            doctorName,
                            doctorSpecialty,
                          }) {
                            provider.updateAt(
                              i,
                              name,
                              dose,
                              imagePath: imagePath,
                              intervalHours: intervalHours ?? 24,
                              startTime: startTime,
                              startDate: startDate,
                              chronicDisease: chronicDisease,
                              doctorName: doctorName,
                              doctorSpecialty: doctorSpecialty,
                            );
                          },
                        ),
                      );
                    },
                    onDelete: () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(AppTranslations.translate('delete_medication', lang)),
                          content: Text('${AppTranslations.translate('confirm_delete_medication', lang)} ${item['name']}؟'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: Text(AppTranslations.translate('cancel', lang)),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                provider.removeAt(i);
                              },
                              child: Text(
                                AppTranslations.translate('delete', lang),
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
