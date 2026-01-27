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