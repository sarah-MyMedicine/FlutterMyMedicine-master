import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/blood_pressure_provider.dart';
import '../components/blood_pressure_form_modal.dart';
import '../components/blood_pressure_report_modal.dart';

class BloodPressurePage extends StatelessWidget {
  const BloodPressurePage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BloodPressureProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('سجل الضغط'), actions: [
        IconButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (_) => Directionality(textDirection: TextDirection.rtl, child: BloodPressureReportModal(avgSys: provider.averageSystolic(), avgDia: provider.averageDiastolic())),
              );
            },
            icon: const Icon(Icons.bar_chart))
      ]),
      body: ListView.builder(
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
                          const PopupMenuItem<String>(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 18),
                                SizedBox(width: 12),
                                Text('تعديل'),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 18, color: Colors.red),
                                SizedBox(width: 12),
                                Text('حذف', style: TextStyle(color: Colors.red)),
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
                              Provider.of<BloodPressureProvider>(context, listen: false).update(i, sys, dia);
                            },
                          ),
                        );
                      } else if (selected == 'delete') {
                        Provider.of<BloodPressureProvider>(context, listen: false).remove(i);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم حذف القراءة')),
                        );
                      }
                    },
                  );
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => BloodPressureFormModal(onSave: (sys, dia) {
              Provider.of<BloodPressureProvider>(context, listen: false).add(sys, dia);
            }),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}