import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/medication_provider.dart';
import '../providers/settings_provider.dart';
import '../services/ocr_service.dart';
import '../utils/translations.dart';
import 'medication_item.dart';
import 'medication_info_modal.dart';
import 'medication_form_modal.dart';

class MedicationList extends StatelessWidget {
  const MedicationList({super.key});

  Future<void> _showAddOptions(BuildContext context) async {
    final lang = Provider.of<SettingsProvider>(context, listen: false).language;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(AppTranslations.translate('add_medication_manually', lang)),
              onTap: () {
                Navigator.of(ctx).pop();
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => MedicationFormModal(
                    initialIntervalHours: null,
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
                      pillCount,
                      warningBarrier,
                    }) {
                      Provider.of<MedicationProvider>(context, listen: false)
                          .add(
                            name,
                            dose,
                            imagePath: imagePath,
                            intervalHours: intervalHours ?? 24,
                            startTime: startTime,
                            startDate: startDate,
                            chronicDisease: chronicDisease,
                            doctorName: doctorName,
                            doctorSpecialty: doctorSpecialty,
                            pillCount: pillCount,
                            warningBarrier: warningBarrier,
                          );
                    },
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: Text(AppTranslations.translate('add_medication_camera', lang)),
              onTap: () async {
                Navigator.of(ctx).pop();
                await _handleAddFromPhoto(context, fromCamera: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(AppTranslations.translate('add_medication_gallery', lang)),
              onTap: () async {
                Navigator.of(ctx).pop();
                await _handleAddFromPhoto(context, fromCamera: false);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAddFromPhoto(
    BuildContext context, {
    required bool fromCamera,
  }) async {
    final ocr = OcrService();
    final path = await ocr.pickImagePath(fromCamera: fromCamera);
    if (path == null) return;
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final result = await ocr.extractFromFile(path);

    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    if (result == null || !context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => MedicationFormModal(
        initialName: result.name,
        initialDose: result.dose,
        initialImagePath: result.imagePath,
        initialIntervalHours: null,
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
          pillCount,
          warningBarrier,
        }) {
          Provider.of<MedicationProvider>(context, listen: false).add(
            name,
            dose,
            imagePath: imagePath,
            intervalHours: intervalHours ?? 24,
            startTime: startTime,
            startDate: startDate,
            chronicDisease: chronicDisease,
            doctorName: doctorName,
            doctorSpecialty: doctorSpecialty,
            pillCount: pillCount,
            warningBarrier: warningBarrier,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String lang) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.local_pharmacy_outlined, color: Color(0xFF57B6A8), size: 42),
        const SizedBox(height: 12),
        Text(
          AppTranslations.translate('no_medications', lang),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF525252),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          AppTranslations.translate('add_medication', lang),
          style: const TextStyle(fontSize: 13, color: Color(0xFF7B7B7B)),
        ),
      ],
    );
  }

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
            Center(
              child: ElevatedButton.icon(
                onPressed: () => _showAddOptions(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF57B6A8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  elevation: 0,
                ),
                icon: const Icon(Icons.add, size: 18),
                label: Text(
                  AppTranslations.translate('add_medication', lang),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: items.isEmpty
                  ? _buildEmptyState(lang)
                  : ListView.builder(
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
                                initialPillCount: int.tryParse(item['pillCountRemaining'] ?? ''),
                                initialWarningBarrier: int.tryParse(item['warningBarrier'] ?? '5'),
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
                                  pillCount,
                                  warningBarrier,
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
                                    pillCount: pillCount,
                                    warningBarrier: warningBarrier,
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
