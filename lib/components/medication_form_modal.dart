import 'dart:io';
import 'package:flutter/material.dart';

class MedicationFormModal extends StatefulWidget {
  // onSave supports optional named params for imagePath, intervalHours, startTime, and startDate
  final void Function(String name, String dose, {String? imagePath, int? intervalHours, String? startTime, String? startDate}) onSave;
  final String? initialName;
  final String? initialDose;
  final String? initialImagePath;
  final int? initialIntervalHours;
  final String? initialStartTime;
  final String? initialStartDate; // ISO date string e.g. YYYY-MM-DD

  const MedicationFormModal({
    super.key,
    required this.onSave,
    this.initialName,
    this.initialDose,
    this.initialImagePath,
    this.initialIntervalHours,
    this.initialStartTime,
    this.initialStartDate,
  });

  @override
  State<MedicationFormModal> createState() => _MedicationFormModalState();
}

class _MedicationFormModalState extends State<MedicationFormModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _doseController;
  String? _imagePath;
  int? _intervalHours;
  TimeOfDay? _startTime;
  DateTime? _startDate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _doseController = TextEditingController(text: widget.initialDose ?? '');
    _imagePath = widget.initialImagePath;
    _intervalHours = widget.initialIntervalHours; // null means user must choose

    // parse initial start time if provided (expects 'HH:mm')
    if (widget.initialStartTime != null) {
      final parts = widget.initialStartTime!.split(':');
      if (parts.length == 2) {
        final h = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        if (h != null && m != null) {
          _startTime = TimeOfDay(hour: h, minute: m);
        }
      }
    }

    // parse initial start date if provided (expects ISO date YYYY-MM-DD or full ISO)
    if (widget.initialStartDate != null) {
      try {
        _startDate = DateTime.parse(widget.initialStartDate!);
      } catch (_) {
        _startDate = null;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _doseController.dispose();
    super.dispose();
  }

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
            const Text(
              'إضافة دواء',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_imagePath != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Image.file(
                      File(_imagePath!),
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                    const SizedBox(width: 8),
                    const Text('تم العثور على الصورة - أكد التفاصيل أدناه'),
                  ],
                ),
              ),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'الاسم'),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'أدخل الاسم' : null,
                  ),
                  TextFormField(
                    controller: _doseController,
                    decoration: const InputDecoration(labelText: 'الجرعة'),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'أدخل الجرعة' : null,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(labelText: 'الفترة (ساعات)'),
                    initialValue: _intervalHours,
                    validator: (v) => (v == null) ? 'اختر الفترة' : null,
                    style: const TextStyle(color: Colors.black),
                    dropdownColor: Colors.white,
                    items: List.generate(24, (i) => i + 1)
                        .map((v) => DropdownMenuItem(
                              value: v,
                              child: Text(v == 1 ? 'كل ساعة' : 'كل $v ساعات', style: const TextStyle(color: Colors.black)),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _intervalHours = v),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: FormField<TimeOfDay>(
                          initialValue: _startTime,
                          validator: (v) => v == null ? 'اختر الوقت' : null,
                          builder: (state) {
                            return InkWell(
                              onTap: () async {
                                final t = await showTimePicker(
                                  context: context,
                                  initialTime: _startTime ?? const TimeOfDay(hour: 8, minute: 0),
                                );
                                if (t != null) {
                                  setState(() {
                                    _startTime = t;
                                    state.didChange(t);
                                  });
                                }
                              },

                              child: InputDecorator(
                                decoration: InputDecoration(labelText: 'وقت أول جرعة', errorText: state.errorText),
                                child: Text(_startTime != null ? _startTime!.format(context) : 'اختر الوقت', style: TextStyle(color: _startTime != null ? Colors.black : Colors.black54)),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FormField<DateTime>(
                          initialValue: _startDate,
                          builder: (state) {
                            return InkWell(
                              onTap: () async {
                                final d = await showDatePicker(
                                  context: context,
                                  initialDate: _startDate ?? DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (d != null) {
                                  setState(() {
                                    _startDate = d;
                                    state.didChange(d);
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: InputDecoration(labelText: 'تاريخ أول جرعة (اختياري)'),
                                child: Text(_startDate != null ? '${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}' : 'اختر التاريخ', style: TextStyle(color: _startDate != null ? Colors.black : Colors.black54)),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState?.validate() ?? false) {
                  String? startTimeStr;
                  String? startDateStr;
                  if (_startTime != null) {
                    startTimeStr = '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}';
                  }
                  if (_startDate != null) {
                    startDateStr = '${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}';
                  }

                  widget.onSave(
                    _nameController.text.trim(),
                    _doseController.text.trim(),
                    imagePath: _imagePath,
                    intervalHours: _intervalHours,
                    startTime: startTimeStr,
                    startDate: startDateStr,
                  );

                  Navigator.of(context).pop();
                } else {
                  // If frequency/time wasn't selected, validators show messages.
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }
}

