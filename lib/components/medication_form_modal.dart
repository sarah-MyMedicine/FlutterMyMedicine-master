import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/medication_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/translations.dart';

class MedicationFormModal extends StatefulWidget {
  // onSave supports optional named params for imagePath, intervalHours, startTime, startDate, chronicDisease, doctorName, and doctorSpecialty
  final void Function(
    String name,
    String dose, {
    String? imagePath,
    int? intervalHours,
    String? startTime,
    String? startDate,
    String? chronicDisease,
    String? doctorName,
    String? doctorSpecialty,
  }) onSave;
  final String? initialName;
  final String? initialDose;
  final String? initialImagePath;
  final int? initialIntervalHours;
  final String? initialStartTime;
  final String? initialStartDate; // ISO date string e.g. YYYY-MM-DD
  final String? initialChronicDisease;
  final String? initialDoctorName;
  final String? initialDoctorSpecialty;

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
    this.initialDoctorName,
    this.initialDoctorSpecialty,
  });

  @override
  State<MedicationFormModal> createState() => _MedicationFormModalState();
}

class _MedicationFormModalState extends State<MedicationFormModal> {
  static const String _addNewDoctorValue = '__add_new_doctor__';

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _doseController;
  late final TextEditingController _doctorNameController;
  late final TextEditingController _doctorSpecialtyController;
  String? _imagePath;
  TimeOfDay? _startTime;
  DateTime? _startDate;
  String? _chronicDisease;
  List<Map<String, String>> _savedDoctors = [];
  String _selectedDoctorValue = _addNewDoctorValue;
  
  // Frequency selection – exactly one type is active at a time
  String _frequencyType = 'daily'; // 'daily', 'weekly', 'monthly'
  int _hoursValue = 8;
  int _weeklyFrequencyTimes = 1;
  int _monthlyFrequencyTimes = 1;

  String _doctorOptionValue(String name, String specialty) => '$name|||$specialty';

  void _loadSavedDoctors() {
    final medicationProvider = Provider.of<MedicationProvider>(context, listen: false);
    _savedDoctors = medicationProvider.savedDoctors;

    final initialDoctorName = (widget.initialDoctorName ?? '').trim();
    final initialDoctorSpecialty = (widget.initialDoctorSpecialty ?? '').trim();

    if (initialDoctorName.isNotEmpty) {
      final matched = _savedDoctors.where((entry) {
        return entry['name'] == initialDoctorName &&
            entry['specialty'] == initialDoctorSpecialty;
      }).toList();

      if (matched.isNotEmpty) {
        _selectedDoctorValue = _doctorOptionValue(
          matched.first['name']!,
          matched.first['specialty']!,
        );
      }
    }
  }

  void _onDoctorSelectionChanged(String value) {
    setState(() {
      _selectedDoctorValue = value;
      if (value == _addNewDoctorValue) return;

      final parts = value.split('|||');
      if (parts.isNotEmpty) {
        _doctorNameController.text = parts[0];
      }
      _doctorSpecialtyController.text = parts.length > 1 ? parts[1] : '';
    });
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _doseController = TextEditingController(text: widget.initialDose ?? '');
    _doctorNameController = TextEditingController(text: widget.initialDoctorName ?? '');
    _doctorSpecialtyController = TextEditingController(text: widget.initialDoctorSpecialty ?? '');
    _imagePath = widget.initialImagePath;
    _chronicDisease = widget.initialChronicDisease;
    _loadSavedDoctors();

    // Initialize frequency based on intervalHours
    if (widget.initialIntervalHours != null) {
      final hours = widget.initialIntervalHours!;
      if (hours <= 24) {
        _frequencyType = 'daily';
        _hoursValue = hours;
      } else if (hours >= 84 && hours <= 168) {
        _frequencyType = 'weekly';
        final timesPerWeek = (168 / hours).round();
        _weeklyFrequencyTimes = timesPerWeek.clamp(1, 7);
      } else if (hours >= 180) {
        _frequencyType = 'monthly';
        final timesPerMonth = (720 / hours).round();
        _monthlyFrequencyTimes = timesPerMonth.clamp(1, 4);
      } else {
        _frequencyType = 'daily';
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
      case 'daily':
        return _hoursValue;
      case 'weekly':
        // e.g. 2×/week → 168 ÷ 2 = 84 h ≈ 3.5 days between doses
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
    _doctorNameController.dispose();
    _doctorSpecialtyController.dispose();
    super.dispose();
  }

  /// Builds a mutually-exclusive frequency selection tile.
  /// Tapping anywhere on the tile activates this [type].
  /// The [trailing] widget (dropdown) is grayed-out and non-interactive when inactive.
  Widget _buildFrequencyOption({
    required String type,
    required String label,
    required Widget trailing,
    required bool active,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _frequencyType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF36BBA0).withOpacity(0.09) : Colors.grey.shade50,
          border: Border.all(
            color: active ? const Color(0xFF36BBA0) : Colors.grey.shade300,
            width: active ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              active ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: active ? const Color(0xFF36BBA0) : Colors.grey.shade400,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: active ? Colors.black87 : Colors.grey,
                  fontWeight: active ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
            IgnorePointer(
              ignoring: !active,
              child: Opacity(opacity: active ? 1.0 : 0.35, child: trailing),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, sp, _) {
        final lang = sp.language;
        final viewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;
        
        return SafeArea(
          top: false,
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(bottom: viewInsetsBottom),
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedDoctorValue,
                    decoration: InputDecoration(
                      labelText: AppTranslations.translate('select_saved_doctor_or_add', lang),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: _addNewDoctorValue,
                        child: Text(AppTranslations.translate('add_new_doctor', lang)),
                      ),
                      ..._savedDoctors.map((entry) {
                        final doctorName = entry['name'] ?? '';
                        final doctorSpecialty = entry['specialty'] ?? '';
                        final label = doctorSpecialty.isEmpty
                            ? doctorName
                            : '$doctorName (${AppTranslations.translate('specialty', lang)}: $doctorSpecialty)';

                        return DropdownMenuItem<String>(
                          value: _doctorOptionValue(doctorName, doctorSpecialty),
                          child: Text(label, overflow: TextOverflow.ellipsis),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      _onDoctorSelectionChanged(value);
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _doctorNameController,
                    decoration: InputDecoration(
                      labelText: AppTranslations.translate('doctor_name', lang),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _doctorSpecialtyController,
                    decoration: InputDecoration(
                      labelText: AppTranslations.translate('specialty', lang),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Frequency Section – pick exactly one
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      AppTranslations.translate('frequency', lang),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Daily option
                  _buildFrequencyOption(
                    type: 'daily',
                    active: _frequencyType == 'daily',
                    label: AppTranslations.translate('every', lang),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButton<int>(
                          value: _hoursValue,
                          underline: const SizedBox(),
                          style: const TextStyle(color: Colors.black, fontSize: 14),
                          dropdownColor: Colors.white,
                          items: List.generate(24, (i) => i + 1).map((v) {
                            return DropdownMenuItem<int>(value: v, child: Text('$v'));
                          }).toList(),
                          onChanged: (v) {
                            if (v != null) setState(() { _hoursValue = v; });
                          },
                        ),
                        const SizedBox(width: 6),
                        Text(AppTranslations.translate('hour', lang),
                            style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Weekly option
                  _buildFrequencyOption(
                    type: 'weekly',
                    active: _frequencyType == 'weekly',
                    label: AppTranslations.translate('every_week', lang),
                    trailing: DropdownButton<int>(
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
                        if (v != null) setState(() { _weeklyFrequencyTimes = v; });
                      },
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Monthly option – max 4 times per month
                  _buildFrequencyOption(
                    type: 'monthly',
                    active: _frequencyType == 'monthly',
                    label: AppTranslations.translate('every_month', lang),
                    trailing: DropdownButton<int>(
                      value: _monthlyFrequencyTimes,
                      underline: const SizedBox(),
                      style: const TextStyle(color: Colors.black, fontSize: 14),
                      dropdownColor: Colors.white,
                      items: List<int>.generate(4, (i) => i + 1)
                          .map((v) => DropdownMenuItem<int>(
                                value: v,
                                child: Text(_getFrequencyLabel(v, lang)),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() { _monthlyFrequencyTimes = v; });
                      },
                    ),
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
                      labelText: AppTranslations.translate('medication_type', lang)
                    ),
                    initialValue: _chronicDisease,
                    style: const TextStyle(color: Colors.black),
                    dropdownColor: Colors.white,
                    items: <DropdownMenuItem<String>>[
                      DropdownMenuItem<String>(
                        value: 'عام',
                        child: Text(
                          AppTranslations.translate('general_medication', lang),
                          style: const TextStyle(color: Colors.black)
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
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? AppTranslations.translate('required_field', lang) : null,
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
                  final doctorName = _doctorNameController.text.trim();
                  final doctorSpecialty = _doctorSpecialtyController.text.trim();

                  widget.onSave(
                    _nameController.text.trim(),
                    _doseController.text.trim(),
                    imagePath: _imagePath,
                    intervalHours: intervalHours,
                    startTime: startTimeStr,
                    startDate: startDateStr,
                    chronicDisease: _chronicDisease,
                    doctorName: doctorName.isEmpty ? null : doctorName,
                    doctorSpecialty: doctorSpecialty.isEmpty ? null : doctorSpecialty,
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
          ),
        );
      },
    );
  }
}

