import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/medication_provider.dart';
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
    final provider = Provider.of<MedicationProvider>(context);
    final items = provider.items;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('الأدوية', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final item = items[i];
              return MedicationItem(
                name: item['name'] ?? '',
                dose: item['dose'] ?? '',
                imagePath: item['imagePath'],
                intervalHours: item['intervalHours'],
                startTime: item['startTime'],
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
                      onSave: (name, dose, {imagePath, intervalHours, startTime, startDate}) {
                        provider.updateAt(i, name, dose, imagePath: imagePath, intervalHours: intervalHours ?? 24, startTime: startTime, startDate: startDate);
                      },
                    ),
                  );
                },
                onDelete: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('حذف الدواء؟'),
                      content: Text('هل أنت متأكد من حذف ${item['name']}؟'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('إلغاء'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            provider.removeAt(i);
                          },
                          child: const Text('حذف', style: TextStyle(color: Colors.red)),
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
  }
}
