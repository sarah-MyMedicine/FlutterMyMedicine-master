import 'package:flutter/material.dart';

class BloodPressureReportModal extends StatelessWidget {
  final double avgSys;
  final double avgDia;
  const BloodPressureReportModal({super.key, required this.avgSys, required this.avgDia});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('تقرير ضغط الدم', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text('متوسط الانقباضي: ${avgSys.toStringAsFixed(1)}'),
              Text('متوسط الانبساطي: ${avgDia.toStringAsFixed(1)}'),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إغلاق'))
            ],
          ),
        ),
      ),
    );
  }
}