import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/blood_sugar_provider.dart';
import '../providers/settings_provider.dart';
import '../components/blood_sugar_form_modal.dart';
import '../components/blood_sugar_report_modal.dart';
import '../utils/translations.dart';

class BloodSugarPage extends StatelessWidget {
  const BloodSugarPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BloodSugarProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final lang = context.read<SettingsProvider>().language;

    return Scaffold(
      appBar: AppBar(title: Text(AppTranslations.translate('blood_sugar_log', lang)), actions: [
        IconButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (_) => Directionality(textDirection: TextDirection.rtl, child: BloodSugarReportModal(avg: provider.average())),
              );
            },
            icon: const Icon(Icons.bar_chart)),
      ]),
      body: Column(
        children: [
          // Target Blood Sugar Card
          Card(
            margin: const EdgeInsets.all(12),
            color: Colors.orange.shade50,
            child: ListTile(
              leading: const Icon(Icons.water_drop, color: Colors.orange),
              title: Text(AppTranslations.translate('target_for_blood_sugar', lang), style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${settingsProvider.targetBloodSugar} mg/dL'),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  _showTargetDialog(context, settingsProvider, lang);
                },
              ),
            ),
          ),
          // Readings List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: provider.readings.length,
              itemBuilder: (context, i) {
          final r = provider.readings[i];
          return Card(
            child: ListTile(
              title: Text('${r.value} mg/dL'),
              subtitle: Text('${r.when}'),
              trailing: Builder(
                builder: (BuildContext buttonContext) {
                  return IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () async {
                      final RenderBox button = buttonContext.findRenderObject() as RenderBox;
                      final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
                      final RelativeRect position = RelativeRect.fromRect(
                        Rect.fromPoints(
                          button.localToGlobal(Offset.zero, ancestor: overlay),
                          button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
                        ),
                        Offset.zero & overlay.size,
                      );
                      
                      final String? selected = await showMenu<String>(
                        context: context,
                        position: position,
                        items: [
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
                      );
                      
                      if (selected == 'edit') {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => BloodSugarFormModal(
                            initialValue: r.value,
                            onSave: (v) {
                              Provider.of<BloodSugarProvider>(context, listen: false).update(
                                i,
                                v,
                                targetBloodSugar: settingsProvider.targetBloodSugar,
                              );
                            },
                          ),
                        );
                      } else if (selected == 'delete') {
                        Provider.of<BloodSugarProvider>(context, listen: false).remove(i);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(AppTranslations.translate('reading_saved', lang))),
                        );
                      }
                    },
                  );
                },
              ),
            ),
          );
        },
      ),          ),
        ],
      ),      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => BloodSugarFormModal(onSave: (v) {
              Provider.of<BloodSugarProvider>(context, listen: false).add(
                v,
                targetBloodSugar: settingsProvider.targetBloodSugar,
              );
            }),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showTargetDialog(BuildContext context, SettingsProvider settingsProvider, String lang) {
    final controller = TextEditingController(text: settingsProvider.targetBloodSugar.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppTranslations.translate('target_for_blood_sugar', lang)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: AppTranslations.translate('target_blood_sugar_level', lang),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppTranslations.translate('cancel', lang)),
          ),
          ElevatedButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value != null) {
                settingsProvider.setTargetBloodSugar(value);
                Navigator.pop(context);
              }
            },
            child: Text(AppTranslations.translate('save', lang)),
          ),
        ],
      ),
    );
  }
}