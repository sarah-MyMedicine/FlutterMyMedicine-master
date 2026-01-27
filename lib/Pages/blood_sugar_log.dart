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