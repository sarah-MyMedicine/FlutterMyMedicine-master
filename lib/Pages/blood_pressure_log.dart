import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/blood_pressure_provider.dart';
import '../providers/settings_provider.dart';
import '../components/blood_pressure_form_modal.dart';
import '../components/blood_pressure_report_modal.dart';
import '../utils/translations.dart';

class BloodPressurePage extends StatelessWidget {
  const BloodPressurePage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BloodPressureProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final lang = context.read<SettingsProvider>().language;

    return Scaffold(
      appBar: AppBar(title: Text(AppTranslations.translate('blood_pressure_log', lang)), actions: [
        IconButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (_) => Directionality(textDirection: TextDirection.rtl, child: BloodPressureReportModal(avgSys: provider.averageSystolic(), avgDia: provider.averageDiastolic())),
              );
            },
            icon: const Icon(Icons.bar_chart)),
      ]),
      body: Column(
        children: [
          // Target Blood Pressure Card
          Card(
            margin: const EdgeInsets.all(12),
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.red.withOpacity(0.2)
                : Colors.red.shade50,
            child: ListTile(
              leading: const Icon(Icons.favorite, color: Colors.red),
              title: Text(AppTranslations.translate('target_for_blood_pressure', lang), style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${settingsProvider.targetSystolic}/${settingsProvider.targetDiastolic}'),
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
              title: Text('${r.systolic}/${r.diastolic}'),
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
                          builder: (_) => BloodPressureFormModal(
                            initialSystolic: r.systolic,
                            initialDiastolic: r.diastolic,
                            onSave: (sys, dia) {
                              Provider.of<BloodPressureProvider>(context, listen: false).update(
                                i,
                                sys,
                                dia,
                                targetSystolic: settingsProvider.targetSystolic,
                                targetDiastolic: settingsProvider.targetDiastolic,
                              );
                            },
                          ),
                        );
                      } else if (selected == 'delete') {
                        Provider.of<BloodPressureProvider>(context, listen: false).remove(i);
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
            builder: (_) => BloodPressureFormModal(onSave: (sys, dia) {
              final targetSys = settingsProvider.targetSystolic;
              final targetDia = settingsProvider.targetDiastolic;
              Provider.of<BloodPressureProvider>(context, listen: false).add(
                sys,
                dia,
                targetSystolic: targetSys,
                targetDiastolic: targetDia,
              );
              final bool high = (sys - targetSys) >= 2 || (dia - targetDia) >= 2;
              final bool low  = (targetSys - sys) >= 2 || (targetDia - dia) >= 2;
              if (high || low) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!context.mounted) return;
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: high ? Colors.red.shade50 : Colors.orange.shade50,
                      title: Row(
                        children: [
                          Icon(Icons.warning_rounded,
                              color: high ? Colors.red : Colors.orange),
                          const SizedBox(width: 8),
                          Text(
                            AppTranslations.translate('bp_danger_title', lang),
                            style: TextStyle(
                                color: high ? Colors.red : Colors.orange,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      content: Text(
                        high
                            ? AppTranslations.translate('bp_danger_high', lang)
                                .replaceAll('{target}', '$targetSys/$targetDia')
                            : AppTranslations.translate('bp_danger_low', lang)
                                .replaceAll('{target}', '$targetSys/$targetDia'),
                        style: const TextStyle(fontSize: 15),
                      ),
                      actions: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  high ? Colors.red : Colors.orange),
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(
                              AppTranslations.translate('ok', lang),
                              style:
                                  const TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                });
              }
            }),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showTargetDialog(BuildContext context, SettingsProvider settingsProvider, String lang) {
    final sysController = TextEditingController(text: settingsProvider.targetSystolic.toString());
    final diaController = TextEditingController(text: settingsProvider.targetDiastolic.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppTranslations.translate('target_for_blood_pressure', lang)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: sysController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: AppTranslations.translate('target_systolic_bp', lang),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[100],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: diaController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: AppTranslations.translate('target_diastolic_bp', lang),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[100],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppTranslations.translate('cancel', lang)),
          ),
          ElevatedButton(
            onPressed: () {
              final sys = int.tryParse(sysController.text);
              final dia = int.tryParse(diaController.text);
              if (sys != null && dia != null) {
                settingsProvider.setTargetSystolic(sys);
                settingsProvider.setTargetDiastolic(dia);
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