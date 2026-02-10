import 'dart:io';
import 'package:flutter/material.dart';

class MedicationInfoModal extends StatelessWidget {
  final String name;
  final String dose;
  final String? imagePath;
  final int intervalHours;
  final String? startTime;
  final String? startDate;

  const MedicationInfoModal({
    super.key,
    required this.name,
    required this.dose,
    this.imagePath,
    this.intervalHours = 24,
    this.startTime,
    this.startDate,
  });


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (imagePath != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Image.file(File(imagePath!), height: 120, fit: BoxFit.cover),
              ),
            Text(
              name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('الجرعة: $dose'),
            const SizedBox(height: 4),
            Text('الفترة: كل $intervalHours ساعة'),
            const SizedBox(height: 4),
            if (startTime != null && startDate != null) Text('أول جرعة: $startDate $startTime'),
            if (startTime != null && startDate == null) Text('أول جرعة: $startTime'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      ),
    );
  }
}
