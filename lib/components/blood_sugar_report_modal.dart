import 'package:flutter/material.dart';

class BloodSugarReportModal extends StatelessWidget {
  final double avg;
  const BloodSugarReportModal({super.key, required this.avg});

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
              const Text('تقرير سكر الدم', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text('المتوسط: ${avg.toStringAsFixed(1)} mg/dL'),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إغلاق'))
            ],
          ),
        ),
      ),
    );
  }
}