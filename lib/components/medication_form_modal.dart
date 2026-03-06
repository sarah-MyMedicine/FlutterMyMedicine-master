import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../utils/translations.dart';

class MedicationFormModal extends StatefulWidget {
  // onSave supports optional named params for imagePath, intervalHours, startTime, startDate, and chronicDisease
  final void Function(String name, String dose, {String? imagePath, int? intervalHours, String? startTime, String? startDate, String? chronicDisease}) onSave;
  final String? initialName;
  final String? initialDose;
  final String? initialImagePath;
  final int? initialIntervalHours;
  final String? initialStartTime;
  final String? initialStartDate; // ISO date string e.g. YYYY-MM-DD
  final String? initialChronicDisease;

  const MedicationFormModal({
    super.key,
    required this.onSave,
    this.initialName,
    this.initialDose,
    this.initialImagePath,
    this.initialIntervalHours,
    this.initialStartTime,
    this.initialStartDate,
    this.initialChronicDisease,
  });

  @override
  State<MedicationFormModal> createState() => _MedicationFormModalState();
}

class _MedicationFormModalState extends State<MedicationFormModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _doseController;
  String? _imagePath;
  TimeOfDay? _startTime;
  DateTime? _startDate;
  String? _chronicDisease;
  
  // Frequency selection
  String _frequencyType = 'hourly'; // 'hourly', 'weekly', 'monthly'
  int _hoursValue = 8;
  int _weeklyFrequencyTimes = 1;
  int _monthlyFrequencyTimes = 1;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _doseController = TextEditingController(text: widget.initialDose ?? '');
    _imagePath = widget.initialImagePath;
    _chronicDisease = widget.initialChronicDisease;

    // Initialize frequency based on intervalHours
    if (widget.initialIntervalHours != null) {
      final hours = widget.initialIntervalHours!;
      if (hours <= 24) {
        _frequencyType = 'hourly';
        _hoursValue = hours;
      } else if (hours >= 84 && hours <= 168) {
        _frequencyType = 'weekly';
        final timesPerWeek = (168 / hours).round();
        _weeklyFrequencyTimes = timesPerWeek.clamp(1, 7);
      } else if (hours >= 180) {
        _frequencyType = 'monthly';
        final timesPerMonth = (720 / hours).round();
        _monthlyFrequencyTimes = timesPerMonth.clamp(1, 7);
      } else {
        _frequencyType = 'hourly';
        _hoursValue = hours;
      }
    }

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

  String _getFrequencyLabel(int times, String lang) {
    switch (times) {
      case 1:
        return AppTranslations.translate('once', lang);
      case 2:
        return AppTranslations.translate('twice', lang);
      case 3:
        return AppTranslations.translate('three_times', lang);
      case 4:
        return AppTranslations.translate('four_times', lang);
      case 5:
        return AppTranslations.translate('five_times', lang);
      case 6:
        return AppTranslations.translate('six_times', lang);
      case 7:
        return AppTranslations.translate('seven_times', lang);
      default:
        return AppTranslations.translate('once', lang);
    }
  }

  int _calculateIntervalHours() {
    switch (_frequencyType) {
      case 'hourly':
        return _hoursValue;
      case 'weekly':
        return (168 / _weeklyFrequencyTimes).round();
      case 'monthly':
        return (720 / _monthlyFrequencyTimes).round();
      default:
        return 24;
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
    return Consumer<SettingsProvider>(
      builder: (context, sp, _) {
        final lang = sp.language;
        
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppTranslations.translate('add_medication', lang),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                    Text(AppTranslations.translate('image_found_confirm', lang)),
                  ],
                ),
              ),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: AppTranslations.translate('medication_name', lang),
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? AppTranslations.translate('required_field', lang) : null,
                  ),
                  TextFormField(
                    controller: _doseController,
                    decoration: InputDecoration(
                      labelText: AppTranslations.translate('dose', lang),
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? AppTranslations.translate('required_field', lang) : null,
                  ),
                  const SizedBox(height: 16),
                  
                  // Frequency Section
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      AppTranslations.translate('frequency', lang),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Every X hours option
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(AppTranslations.translate('hour', lang), style: const TextStyle(fontSize: 15)),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButton<int>(
                          value: _hoursValue,
                          underline: const SizedBox(),
                          style: const TextStyle(color: Colors.black, fontSize: 14),
                          dropdownColor: Colors.white,
                          items: List.generate(24, (i) => i + 1).map((v) {
                            return DropdownMenuItem<int>(
                              value: v,
                              child: Text('$v'),
                            );
                          }).toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setState(() {
                                _frequencyType = 'hourly';
                                _hoursValue = v;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(AppTranslations.translate('every', lang), style: const TextStyle(fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Every week option
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButton<int>(
                          value: _weeklyFrequencyTimes,
                          underline: const SizedBox(),
                          style: const TextStyle(color: Colors.black, fontSize: 14),
                          dropdownColor: Colors.white,
                          items: List<int>.generate(7, (i) => i + 1)
                              .map((v) => DropdownMenuItem<int>(
                                    value: v,
                                    child: Text(_getFrequencyLabel(v, lang)),
                                  ))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setState(() {
                                _frequencyType = 'weekly';
                                _weeklyFrequencyTimes = v;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(AppTranslations.translate('every_week', lang), style: const TextStyle(fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Every month option
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButton<int>(
                          value: _monthlyFrequencyTimes,
                          underline: const SizedBox(),
                          style: const TextStyle(color: Colors.black, fontSize: 14),
                          dropdownColor: Colors.white,
                          items: List<int>.generate(7, (i) => i + 1)
                              .map((v) => DropdownMenuItem<int>(
                                    value: v,
                                    child: Text(_getFrequencyLabel(v, lang)),
                                  ))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setState(() {
                                _frequencyType = 'monthly';
                                _monthlyFrequencyTimes = v;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(AppTranslations.translate('every_month', lang), style: const TextStyle(fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: FormField<TimeOfDay>(
                          initialValue: _startTime,
                          validator: (v) => v == null ? AppTranslations.translate('choose_time', lang) : null,
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
                                decoration: InputDecoration(
                                  labelText: AppTranslations.translate('first_dose_time', lang),
                                  errorText: state.errorText
                                ),
                                child: Text(
                                  _startTime != null ? _startTime!.format(context) : AppTranslations.translate('choose_time', lang),
                                  style: TextStyle(color: _startTime != null ? Colors.black : Colors.black54)
                                ),
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
                                decoration: InputDecoration(
                                  labelText: AppTranslations.translate('first_dose_date_optional', lang)
                                ),
                                child: Text(
                                  _startDate != null ? '${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}' : AppTranslations.translate('choose_date', lang),
                                  style: TextStyle(color: _startDate != null ? Colors.black : Colors.black54)
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: AppTranslations.translate('medication_type_optional', lang)
                    ),
                    value: _chronicDisease,
                    style: const TextStyle(color: Colors.black),
                    dropdownColor: Colors.white,
                    items: <DropdownMenuItem<String>>[
                      DropdownMenuItem<String>(
                        value: null,
                        child: Text(
                          AppTranslations.translate('general_medication', lang),
                          style: const TextStyle(color: Colors.black54)
                        ),
                      ),
                      DropdownMenuItem<String>(
                        value: 'ارتفاع ضغط الدم',
                        child: Text(
                          AppTranslations.translate('blood_pressure_medication', lang),
                          style: const TextStyle(color: Colors.black)
                        ),
                      ),
                      DropdownMenuItem<String>(
                        value: 'السكري',
                        child: Text(
                          AppTranslations.translate('blood_sugar_medication', lang),
                          style: const TextStyle(color: Colors.black)
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _chronicDisease = v),
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

                  // Calculate interval hours from frequency selection
                  final intervalHours = _calculateIntervalHours();

                  widget.onSave(
                    _nameController.text.trim(),
                    _doseController.text.trim(),
                    imagePath: _imagePath,
                    intervalHours: intervalHours,
                    startTime: startTimeStr,
                    startDate: startDateStr,
                    chronicDisease: _chronicDisease,
                  );

                  Navigator.of(context).pop();
                } else {
                  // If frequency/time wasn't selected, validators show messages.
                }
              },
              child: Text(AppTranslations.translate('save', lang)),
            ),
              ],
            ),
          ),
        );
      },
    );
  }
}

