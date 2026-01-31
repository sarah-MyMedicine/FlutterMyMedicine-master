import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/blood_sugar_provider.dart';
import '../components/blood_sugar_form_modal.dart';
import '../components/blood_sugar_report_modal.dart';

class BloodSugarPage extends StatelessWidget {
  const BloodSugarPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BloodSugarProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('سجل السكر'), actions: [
        IconButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (_) => Directionality(textDirection: TextDirection.rtl, child: BloodSugarReportModal(avg: provider.average())),
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
                          builder: (_) => BloodSugarFormModal(
                            initialValue: r.value,
                            onSave: (v) {
                              Provider.of<BloodSugarProvider>(context, listen: false).update(i, v);
                            },
                          ),
                        );
                      } else if (selected == 'delete') {
                        Provider.of<BloodSugarProvider>(context, listen: false).remove(i);
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
            builder: (_) => BloodSugarFormModal(onSave: (v) {
              Provider.of<BloodSugarProvider>(context, listen: false).add(v);
            }),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}