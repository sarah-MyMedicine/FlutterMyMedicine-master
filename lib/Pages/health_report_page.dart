import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/medication_provider.dart';
import '../providers/adherence_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/blood_pressure_provider.dart';
import '../providers/blood_sugar_provider.dart';
import '../utils/translations.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pdf/pdf.dart' as pdflib;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class HealthReportPage extends StatefulWidget {
  const HealthReportPage({super.key});

  @override
  State<HealthReportPage> createState() => _HealthReportPageState();
}

class _HealthReportPageState extends State<HealthReportPage> {
  int _selectedDays = 7;
  bool _isLocaleInitialized = false;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _initializeLocale();
  }

  Future<void> _initializeLocale() async {
    await initializeDateFormatting('ar', null);
    setState(() {
      _isLocaleInitialized = true;
    });
  }

  String _getMedicationTypeText(String? chronicDisease, String lang) {
    if (chronicDisease == null || chronicDisease.isEmpty) return AppTranslations.translate('no_medication_type', lang);
    if (chronicDisease == 'ارتفاع ضغط الدم') return AppTranslations.translate('bp_medication_short', lang);
    if (chronicDisease == 'السكري') return AppTranslations.translate('bs_medication_short', lang);
    return chronicDisease;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLocaleInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final medicationProvider = Provider.of<MedicationProvider>(context);
    final adherenceProvider = Provider.of<AdherenceProvider>(context);
    final bloodPressureProvider = Provider.of<BloodPressureProvider>(context);
    final bloodSugarProvider = Provider.of<BloodSugarProvider>(context);

    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        final lang = settingsProvider.language;
        final now = DateTime.now();
        final startDate = now.subtract(Duration(days: _selectedDays));
        final dateFormat = DateFormat('d MMMM yyyy', lang == 'ar' ? 'ar' : 'en');
        
        final bloodPressureEnabled = settingsProvider.chronicDiseases.contains('ارتفاع ضغط الدم');
        final bloodSugarEnabled = settingsProvider.chronicDiseases.contains('السكري');

        return Directionality(
          textDirection: lang == 'ar' ? ui.TextDirection.rtl : ui.TextDirection.ltr,
          child: Scaffold(
            backgroundColor: Colors.grey[50],
            appBar: AppBar(
            leading: IconButton(
              icon: Icon(lang == 'ar' ? Icons.arrow_forward : Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(AppTranslations.translate('health_report_title', lang)),
            actions: [
              PopupMenuButton<int>(
                initialValue: _selectedDays,
                child: Chip(
                  label: Text(
                    _selectedDays == 7
                        ? AppTranslations.translate('last_7_days', lang)
                        : _selectedDays == 30
                        ? AppTranslations.translate('last_30_days', lang)
                        : AppTranslations.translate('last_90_days', lang),
                  ),
                ),
                onSelected: (value) {
                  setState(() {
                    _selectedDays = value;
                  });
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<int>>[
                  PopupMenuItem<int>(
                    value: 7,
                    child: Text(AppTranslations.translate('last_7_days', lang)),
                  ),
                  PopupMenuItem<int>(
                    value: 30,
                    child: Text(AppTranslations.translate('last_30_days', lang)),
                  ),
                  PopupMenuItem<int>(
                    value: 90,
                    child: Text(AppTranslations.translate('last_90_days', lang)),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                tooltip: AppTranslations.translate('print_save_pdf', lang),
                onPressed: () async {
                  await _showExportDialog(
                    context,
                    settingsProvider,
                    medicationProvider,
                    adherenceProvider,
                    bloodPressureProvider,
                    bloodSugarProvider,
                    startDate,
                    now,
                    lang,
                  );
                },
              ),
            ],
          ),
            body: Column(
            children: [
              // Header card with tabs
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [settingsProvider.themeColor, Color.lerp(settingsProvider.themeColor, Colors.black, 0.15) ?? settingsProvider.themeColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    const Icon(Icons.health_and_safety, color: Colors.white, size: 40),
                    const SizedBox(height: 8),
                    Text(
                      '${AppTranslations.translate('report_for', lang)} ${settingsProvider.name}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${AppTranslations.translate('period', lang)}: ${dateFormat.format(startDate)} - ${dateFormat.format(now)}',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    // Tab buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildTabButton(AppTranslations.translate('blood_pressure_tab', lang), 0, lang),
                        _buildTabButton(AppTranslations.translate('blood_sugar_tab', lang), 1, lang),
                        _buildTabButton(AppTranslations.translate('medications_tab', lang), 2, lang),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Progress indicator
                    Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white30,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Align(
                        alignment: lang == 'ar' ? Alignment.centerRight : Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: (_selectedTab + 1) / 3,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              // Content area
              Expanded(
                child: _buildTabContent(
                  medicationProvider,
                  adherenceProvider,
                  bloodPressureProvider,
                  bloodSugarProvider,
                  bloodPressureEnabled,
                  bloodSugarEnabled,
                  startDate,
                  lang,
                ),
              ),
            ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabButton(String label, int index, String lang) {
    final isSelected = _selectedTab == index;
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? settingsProvider.themeColor : Colors.white,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(
    MedicationProvider medicationProvider,
    AdherenceProvider adherenceProvider,
    BloodPressureProvider bloodPressureProvider,
    BloodSugarProvider bloodSugarProvider,
    bool bloodPressureEnabled,
    bool bloodSugarEnabled,
    DateTime startDate,
    String lang,
  ) {
    switch (_selectedTab) {
      case 0:
        return _buildBloodPressureTab(
          medicationProvider,
          adherenceProvider,
          bloodPressureProvider,
          bloodPressureEnabled,
          startDate,
          lang,
        );
      case 1:
        return _buildBloodSugarTab(
          medicationProvider,
          adherenceProvider,
          bloodSugarProvider,
          bloodSugarEnabled,
          startDate,
          lang,
        );
      case 2:
        return _buildMedicationsTab(
          medicationProvider,
          adherenceProvider,
          startDate,
          lang,
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildBloodPressureTab(
    MedicationProvider medicationProvider,
    AdherenceProvider adherenceProvider,
    BloodPressureProvider bloodPressureProvider,
    bool bloodPressureEnabled,
    DateTime startDate,
    String lang,
  ) {
    if (!bloodPressureEnabled) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            AppTranslations.translate('bp_not_enabled', lang),
            style: const TextStyle(color: Colors.grey, fontSize: 16),
            textAlign: lang == 'ar' ? TextAlign.right : TextAlign.left,
          ),
        ),
      );
    }

    final bpReadings = bloodPressureProvider.readings
        .where((r) => r.when.isAfter(startDate))
        .toList()
      ..sort((a, b) => b.when.compareTo(a.when));

    final bpMedsTaken = adherenceProvider.logs
        .where((log) {
          if (!log.when.isAfter(startDate) || !log.taken) return false;
          final med = medicationProvider.items.firstWhere(
            (m) => m['name'] == log.medicationName,
            orElse: () => {},
          );
          return med.isNotEmpty && med['chronicDisease'] == 'ارتفاع ضغط الدم';
        })
        .toList()
      ..sort((a, b) => b.when.compareTo(a.when));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Blood Pressure Readings Table
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    
                    children: [
                      const Icon(Icons.favorite, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        AppTranslations.translate('bp_readings_title', lang),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (bpReadings.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          AppTranslations.translate('no_bp_readings', lang),
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(Colors.red.shade50),
                        border: TableBorder.all(color: Colors.grey.shade300),
                        columns: [
                          DataColumn(label: Text(AppTranslations.translate('date_col', lang), style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text(AppTranslations.translate('time_col', lang), style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text(AppTranslations.translate('systolic', lang), style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text(AppTranslations.translate('diastolic', lang), style: const TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: bpReadings.map((reading) {
                          final dateFormat = DateFormat('d/M/yyyy', lang == 'ar' ? 'ar' : 'en');
                          final timeFormat = DateFormat('h:mm a', lang == 'ar' ? 'ar' : 'en');
                          return DataRow(
                            cells: [
                              DataCell(Text(dateFormat.format(reading.when))),
                              DataCell(Text(timeFormat.format(reading.when))),
                              DataCell(Text('${reading.systolic}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red))),
                              DataCell(Text('${reading.diastolic}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Blood Pressure Medications Table
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    
                    children: [
                      const Icon(Icons.medication, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        AppTranslations.translate('bp_meds_taken_title', lang),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (bpMedsTaken.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          AppTranslations.translate('no_bp_meds_taken', lang),
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(Colors.blue.shade50),
                        border: TableBorder.all(color: Colors.grey.shade300),
                        columns: [
                          DataColumn(label: Text(AppTranslations.translate('date_col', lang), style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text(AppTranslations.translate('time_col', lang), style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text(AppTranslations.translate('medication_name', lang), style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text(AppTranslations.translate('dose', lang), style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text(AppTranslations.translate('disease_col', lang), style: const TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: bpMedsTaken.map((log) {
                          final dateFormat = DateFormat('d/M/yyyy', lang == 'ar' ? 'ar' : 'en');
                          final timeFormat = DateFormat('h:mm a', lang == 'ar' ? 'ar' : 'en');
                          return DataRow(
                            cells: [
                              DataCell(Text(dateFormat.format(log.when))),
                              DataCell(Text(timeFormat.format(log.when))),
                              DataCell(Text(log.medicationName, style: const TextStyle(fontWeight: FontWeight.bold))),
                              DataCell(Text(log.dose)),
                              DataCell(Text(AppTranslations.translate('chronic_disease_hypertension', lang), style: TextStyle(fontSize: 11, color: Colors.red.shade700))),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBloodSugarTab(
    MedicationProvider medicationProvider,
    AdherenceProvider adherenceProvider,
    BloodSugarProvider bloodSugarProvider,
    bool bloodSugarEnabled,
    DateTime startDate,
    String lang,
  ) {
    if (!bloodSugarEnabled) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            AppTranslations.translate('bs_not_enabled', lang),
            style: const TextStyle(color: Colors.grey, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final sugarReadings = bloodSugarProvider.readings
        .where((r) => r.when.isAfter(startDate))
        .toList()
      ..sort((a, b) => b.when.compareTo(a.when));

    final sugarMedsTaken = adherenceProvider.logs
        .where((log) {
          if (!log.when.isAfter(startDate) || !log.taken) return false;
          final med = medicationProvider.items.firstWhere(
            (m) => m['name'] == log.medicationName,
            orElse: () => {},
          );
          return med.isNotEmpty && med['chronicDisease'] == 'السكري';
        })
        .toList()
      ..sort((a, b) => b.when.compareTo(a.when));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Blood Sugar Readings Table
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    
                    children: [
                      const Icon(Icons.water_drop, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        AppTranslations.translate('bs_readings_title', lang),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (sugarReadings.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          AppTranslations.translate('no_bs_readings', lang),
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(Colors.orange.shade50),
                        border: TableBorder.all(color: Colors.grey.shade300),
                        columns: [
                          DataColumn(label: Text(AppTranslations.translate('date_col', lang), style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text(AppTranslations.translate('time_col', lang), style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text(AppTranslations.translate('reading_mg_dl', lang), style: const TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: sugarReadings.map((reading) {
                          final dateFormat = DateFormat('d/M/yyyy', lang == 'ar' ? 'ar' : 'en');
                          final timeFormat = DateFormat('h:mm a', lang == 'ar' ? 'ar' : 'en');
                          return DataRow(
                            cells: [
                              DataCell(Text(dateFormat.format(reading.when))),
                              DataCell(Text(timeFormat.format(reading.when))),
                              DataCell(Text('${reading.value}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange))),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Blood Sugar Medications Table
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    
                    children: [
                      const Icon(Icons.medication, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        AppTranslations.translate('bs_meds_taken_title', lang),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (sugarMedsTaken.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          AppTranslations.translate('no_bs_meds_taken', lang),
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(Colors.orange.shade50),
                        border: TableBorder.all(color: Colors.grey.shade300),
                        columns: [
                          DataColumn(label: Text(AppTranslations.translate('date_col', lang), style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text(AppTranslations.translate('time_col', lang), style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text(AppTranslations.translate('medication_name', lang), style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text(AppTranslations.translate('dose', lang), style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text(AppTranslations.translate('disease_col', lang), style: const TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: sugarMedsTaken.map((log) {
                          final dateFormat = DateFormat('d/M/yyyy', lang == 'ar' ? 'ar' : 'en');
                          final timeFormat = DateFormat('h:mm a', lang == 'ar' ? 'ar' : 'en');
                          return DataRow(
                            cells: [
                              DataCell(Text(dateFormat.format(log.when))),
                              DataCell(Text(timeFormat.format(log.when))),
                              DataCell(Text(log.medicationName, style: const TextStyle(fontWeight: FontWeight.bold))),
                              DataCell(Text(log.dose)),
                              DataCell(Text(AppTranslations.translate('chronic_disease_diabetes', lang), style: TextStyle(fontSize: 11, color: Colors.orange.shade700))),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationsTab(
    MedicationProvider medicationProvider,
    AdherenceProvider adherenceProvider,
    DateTime startDate,
    String lang,
  ) {
    final otherMedsTaken = adherenceProvider.logs
        .where((log) {
          if (!log.when.isAfter(startDate) || !log.taken) return false;
          final med = medicationProvider.items.firstWhere(
            (m) => m['name'] == log.medicationName,
            orElse: () => {},
          );
          final disease = med.isNotEmpty ? med['chronicDisease'] : null;
          return disease != 'ارتفاع ضغط الدم' && disease != 'السكري';
        })
        .toList()
      ..sort((a, b) => b.when.compareTo(a.when));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                
                children: [
                  const Icon(Icons.medication_liquid, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    AppTranslations.translate('other_meds_taken_title', lang),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (otherMedsTaken.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      AppTranslations.translate('no_other_meds_taken', lang),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(Colors.green.shade50),
                    border: TableBorder.all(color: Colors.grey.shade300),
                    columns: [
                      DataColumn(label: Text(AppTranslations.translate('date_col', lang), style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text(AppTranslations.translate('time_col', lang), style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text(AppTranslations.translate('medication_name', lang), style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text(AppTranslations.translate('dose', lang), style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text(AppTranslations.translate('medication_type_col', lang), style: const TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: otherMedsTaken.map((log) {
                      final dateFormat = DateFormat('d/M/yyyy', lang == 'ar' ? 'ar' : 'en');
                      final timeFormat = DateFormat('h:mm a', lang == 'ar' ? 'ar' : 'en');
                      final med = medicationProvider.items.firstWhere(
                        (m) => m['name'] == log.medicationName,
                        orElse: () => {},
                      );
                      final disease = med.isNotEmpty && med['chronicDisease'] != null 
                          ? med['chronicDisease'] 
                          : AppTranslations.translate('no_medication_type', lang);
                      return DataRow(
                        cells: [
                          DataCell(Text(dateFormat.format(log.when))),
                          DataCell(Text(timeFormat.format(log.when))),
                          DataCell(Text(log.medicationName, style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text(log.dose)),
                          DataCell(Text(_getMedicationTypeText(disease, lang), style: TextStyle(fontSize: 11, color: Colors.green.shade700))),
                        ],
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showExportDialog(
    BuildContext context,
    SettingsProvider settingsProvider,
    MedicationProvider medicationProvider,
    AdherenceProvider adherenceProvider,
    BloodPressureProvider bloodPressureProvider,
    BloodSugarProvider bloodSugarProvider,
    DateTime startDate,
    DateTime now,
    String lang,
  ) async {
    final bloodPressureEnabled = settingsProvider.chronicDiseases.contains('ارتفاع ضغط الدم');
    final bloodSugarEnabled = settingsProvider.chronicDiseases.contains('السكري');

    return showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(AppTranslations.translate('export_dialog_title', lang)),
          content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(AppTranslations.translate('export_dialog_text', lang)),
                const SizedBox(height: 16),
                if (bloodPressureEnabled)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.favorite),
                    label: Text(AppTranslations.translate('bp_and_meds_btn', lang)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red.shade900,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _generatePdf(
                        context,
                        settingsProvider,
                        medicationProvider,
                        adherenceProvider,
                        bloodPressureProvider,
                        bloodSugarProvider,
                        startDate,
                        now,
                        'bloodPressure',
                        lang,
                      );
                    },
                  ),
                if (bloodPressureEnabled) const SizedBox(height: 8),
                if (bloodSugarEnabled)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.water_drop),
                    label: Text(AppTranslations.translate('bs_and_meds_btn', lang)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade50,
                      foregroundColor: Colors.orange.shade900,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _generatePdf(
                        context,
                        settingsProvider,
                        medicationProvider,
                        adherenceProvider,
                        bloodPressureProvider,
                        bloodSugarProvider,
                        startDate,
                        now,
                        'bloodSugar',
                        lang,
                      );
                    },
                  ),
                if (bloodSugarEnabled) const SizedBox(height: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.medication_liquid),
                  label: Text(AppTranslations.translate('other_meds_btn', lang)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade50,
                    foregroundColor: Colors.green.shade900,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _generatePdf(
                      context,
                      settingsProvider,
                      medicationProvider,
                      adherenceProvider,
                      bloodPressureProvider,
                      bloodSugarProvider,
                      startDate,
                      now,
                      'medications',
                      lang,
                    );
                  },
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.list_alt),
                  label: Text(AppTranslations.translate('export_all_btn', lang)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade50,
                    foregroundColor: Colors.teal.shade900,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _generatePdf(
                      context,
                      settingsProvider,
                      medicationProvider,
                      adherenceProvider,
                      bloodPressureProvider,
                      bloodSugarProvider,
                      startDate,
                      now,
                      'all',
                      lang,
                    );
                  },
                ),
              ],
            ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(AppTranslations.translate('cancel', lang)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _generatePdf(
    BuildContext context,
    SettingsProvider settingsProvider,
    MedicationProvider medicationProvider,
    AdherenceProvider adherenceProvider,
    BloodPressureProvider bloodPressureProvider,
    BloodSugarProvider bloodSugarProvider,
    DateTime startDate,
    DateTime now,
    String exportType,
    String lang,
  ) async {
    final doc = pw.Document();
    final dateFormat = DateFormat('d MMMM yyyy', lang == 'ar' ? 'ar' : 'en');
    
    final bloodPressureEnabled = settingsProvider.chronicDiseases.contains('ارتفاع ضغط الدم');
    final bloodSugarEnabled = settingsProvider.chronicDiseases.contains('السكري');

    // Load Arabic font
    final arabicFont = await PdfGoogleFonts.cairoRegular();
    final arabicFontBold = await PdfGoogleFonts.cairoBold();

    if (exportType == 'all') {
      // Export all three types in separate pages
      if (bloodPressureEnabled) {
        await _addBloodPressurePage(doc, settingsProvider, medicationProvider, adherenceProvider, bloodPressureProvider, startDate, now, arabicFont, arabicFontBold, dateFormat, lang);
      }
      if (bloodSugarEnabled) {
        await _addBloodSugarPage(doc, settingsProvider, medicationProvider, adherenceProvider, bloodSugarProvider, startDate, now, arabicFont, arabicFontBold, dateFormat, lang);
      }
      await _addMedicationsPage(doc, settingsProvider, medicationProvider, adherenceProvider, startDate, now, arabicFont, arabicFontBold, dateFormat, lang);
    } else if (exportType == 'bloodPressure') {
      await _addBloodPressurePage(doc, settingsProvider, medicationProvider, adherenceProvider, bloodPressureProvider, startDate, now, arabicFont, arabicFontBold, dateFormat, lang);
    } else if (exportType == 'bloodSugar') {
      await _addBloodSugarPage(doc, settingsProvider, medicationProvider, adherenceProvider, bloodSugarProvider, startDate, now, arabicFont, arabicFontBold, dateFormat, lang);
    } else if (exportType == 'medications') {
      await _addMedicationsPage(doc, settingsProvider, medicationProvider, adherenceProvider, startDate, now, arabicFont, arabicFontBold, dateFormat, lang);
    }

    // Show print/save dialog
    String fileName = lang == 'ar' ? 'تقرير_صحي' : 'health_report';
    if (exportType == 'bloodPressure') {
      fileName = lang == 'ar' ? 'تقرير_ضغط_الدم' : 'blood_pressure_report';
    } else if (exportType == 'bloodSugar') fileName = lang == 'ar' ? 'تقرير_سكر_الدم' : 'blood_sugar_report';
    else if (exportType == 'medications') fileName = lang == 'ar' ? 'تقرير_الأدوية' : 'medications_report';
    
    await Printing.layoutPdf(
      onLayout: (pdflib.PdfPageFormat format) async => doc.save(),
      name: '${fileName}_${DateFormat('yyyy-MM-dd').format(now)}.pdf',
    );
  }

  Future<void> _addBloodPressurePage(
    pw.Document doc,
    SettingsProvider settingsProvider,
    MedicationProvider medicationProvider,
    AdherenceProvider adherenceProvider,
    BloodPressureProvider bloodPressureProvider,
    DateTime startDate,
    DateTime now,
    pw.Font arabicFont,
    pw.Font arabicFontBold,
    DateFormat dateFormat,
    String lang,
  ) async {
    final isArabic = lang == 'ar';
    final pdfTextDirection = isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr;

    final bpReadings = bloodPressureProvider.readings
        .where((r) => r.when.isAfter(startDate))
        .toList()
      ..sort((a, b) => b.when.compareTo(a.when));

    final bpMedsTaken = adherenceProvider.logs
        .where((log) {
          if (!log.when.isAfter(startDate) || !log.taken) return false;
          final med = medicationProvider.items.firstWhere(
            (m) => m['name'] == log.medicationName,
            orElse: () => {},
          );
          return med.isNotEmpty && med['chronicDisease'] == 'ارتفاع ضغط الدم';
        })
        .toList()
      ..sort((a, b) => b.when.compareTo(a.when));

    doc.addPage(
      pw.MultiPage(
        pageFormat: pdflib.PdfPageFormat.a4,
        textDirection: pdfTextDirection,
        theme: pw.ThemeData.withFont(
          base: arabicFont,
          bold: arabicFontBold,
        ),
        build: (pw.Context context) {
          return [
            // Header
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: pdflib.PdfColors.red50,
                border: pw.Border.all(color: pdflib.PdfColors.red200),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                children: [
                  pw.Text(
                    AppTranslations.translate('bp_report_title_pdf', lang),
                    style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: pdflib.PdfColors.red900),
                    textDirection: pdfTextDirection,
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    settingsProvider.name,
                    style: const pw.TextStyle(fontSize: 18),
                    textDirection: pdfTextDirection,
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    '${AppTranslations.translate('period', lang)}: ${dateFormat.format(startDate)} - ${dateFormat.format(now)}',
                    style: const pw.TextStyle(color: pdflib.PdfColors.grey700),
                    textDirection: pdfTextDirection,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 24),

            // Blood Pressure Readings
            pw.Text(
              AppTranslations.translate('bp_readings_title', lang),
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: pdflib.PdfColors.red900),
              textDirection: pdfTextDirection,
            ),
            pw.SizedBox(height: 12),
            if (bpReadings.isEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.all(16),
                child: pw.Text(
                  AppTranslations.translate('no_bp_readings', lang),
                  style: const pw.TextStyle(color: pdflib.PdfColors.grey700),
                  textDirection: pdfTextDirection,
                ),
              )
            else
              pw.TableHelper.fromTextArray(
                context: context,
                border: pw.TableBorder.all(color: pdflib.PdfColors.grey300),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                headerDecoration: const pw.BoxDecoration(color: pdflib.PdfColors.red100),
                cellHeight: 25,
                cellAlignments: {
                  0: pw.Alignment.center,
                  1: pw.Alignment.center,
                  2: pw.Alignment.center,
                  3: pw.Alignment.center,
                },
                headers: [
                  AppTranslations.translate('date_col', lang),
                  AppTranslations.translate('time_col', lang),
                  AppTranslations.translate('systolic', lang),
                  AppTranslations.translate('diastolic', lang),
                ],
                data: bpReadings.map((reading) {
                  return [
                    DateFormat('d/M/yyyy', isArabic ? 'ar' : 'en').format(reading.when),
                    DateFormat('h:mm a', isArabic ? 'ar' : 'en').format(reading.when),
                    '${reading.systolic}',
                    '${reading.diastolic}',
                  ];
                }).toList(),
              ),
            pw.SizedBox(height: 24),

            // Blood Pressure Medications
            pw.Text(
              AppTranslations.translate('bp_meds_taken_title', lang),
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: pdflib.PdfColors.blue900),
              textDirection: pdfTextDirection,
            ),
            pw.SizedBox(height: 12),
            if (bpMedsTaken.isEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.all(16),
                child: pw.Text(
                  AppTranslations.translate('no_bp_meds_taken', lang),
                  style: const pw.TextStyle(color: pdflib.PdfColors.grey700),
                  textDirection: pdfTextDirection,
                ),
              )
            else
              pw.TableHelper.fromTextArray(
                context: context,
                border: pw.TableBorder.all(color: pdflib.PdfColors.grey300),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                headerDecoration: const pw.BoxDecoration(color: pdflib.PdfColors.blue100),
                cellHeight: 25,
                cellAlignments: {
                  0: pw.Alignment.center,
                  1: pw.Alignment.center,
                  2: pw.Alignment.centerRight,
                  3: pw.Alignment.center,
                },
                headers: [
                  AppTranslations.translate('date_col', lang),
                  AppTranslations.translate('time_col', lang),
                  AppTranslations.translate('medication_name', lang),
                  AppTranslations.translate('dose', lang),
                ],
                data: bpMedsTaken.map((log) {
                  return [
                    DateFormat('d/M/yyyy', isArabic ? 'ar' : 'en').format(log.when),
                    DateFormat('h:mm a', isArabic ? 'ar' : 'en').format(log.when),
                    log.medicationName,
                    log.dose,
                  ];
                }).toList(),
              ),
            pw.SizedBox(height: 24),

            // Disclaimer
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: pdflib.PdfColors.red50,
                border: pw.Border.all(color: pdflib.PdfColors.red200),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Text(
                AppTranslations.translate('disclaimer_text', lang),
                style: const pw.TextStyle(color: pdflib.PdfColors.red700, fontSize: 12),
                textAlign: pw.TextAlign.center,
                textDirection: pdfTextDirection,
              ),
            ),
          ];
        },
      ),
    );
  }

  Future<void> _addBloodSugarPage(
    pw.Document doc,
    SettingsProvider settingsProvider,
    MedicationProvider medicationProvider,
    AdherenceProvider adherenceProvider,
    BloodSugarProvider bloodSugarProvider,
    DateTime startDate,
    DateTime now,
    pw.Font arabicFont,
    pw.Font arabicFontBold,
    DateFormat dateFormat,
    String lang,
  ) async {
    final isArabic = lang == 'ar';
    final pdfTextDirection = isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr;

    final sugarReadings = bloodSugarProvider.readings
        .where((r) => r.when.isAfter(startDate))
        .toList()
      ..sort((a, b) => b.when.compareTo(a.when));

    final sugarMedsTaken = adherenceProvider.logs
        .where((log) {
          if (!log.when.isAfter(startDate) || !log.taken) return false;
          final med = medicationProvider.items.firstWhere(
            (m) => m['name'] == log.medicationName,
            orElse: () => {},
          );
          return med.isNotEmpty && med['chronicDisease'] == 'السكري';
        })
        .toList()
      ..sort((a, b) => b.when.compareTo(a.when));

    doc.addPage(
      pw.MultiPage(
        pageFormat: pdflib.PdfPageFormat.a4,
        textDirection: pdfTextDirection,
        theme: pw.ThemeData.withFont(
          base: arabicFont,
          bold: arabicFontBold,
        ),
        build: (pw.Context context) {
          return [
            // Header
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: pdflib.PdfColors.orange50,
                border: pw.Border.all(color: pdflib.PdfColors.orange200),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                children: [
                  pw.Text(
                    AppTranslations.translate('bs_report_title_pdf', lang),
                    style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: pdflib.PdfColors.orange900),
                    textDirection: pdfTextDirection,
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    settingsProvider.name,
                    style: const pw.TextStyle(fontSize: 18),
                    textDirection: pdfTextDirection,
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    '${AppTranslations.translate('period', lang)}: ${dateFormat.format(startDate)} - ${dateFormat.format(now)}',
                    style: const pw.TextStyle(color: pdflib.PdfColors.grey700),
                    textDirection: pdfTextDirection,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 24),

            // Blood Sugar Readings
            pw.Text(
              AppTranslations.translate('bs_readings_title', lang),
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: pdflib.PdfColors.orange900),
              textDirection: pdfTextDirection,
            ),
            pw.SizedBox(height: 12),
            if (sugarReadings.isEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.all(16),
                child: pw.Text(
                  AppTranslations.translate('no_bs_readings', lang),
                  style: const pw.TextStyle(color: pdflib.PdfColors.grey700),
                  textDirection: pdfTextDirection,
                ),
              )
            else
              pw.TableHelper.fromTextArray(
                context: context,
                border: pw.TableBorder.all(color: pdflib.PdfColors.grey300),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                headerDecoration: const pw.BoxDecoration(color: pdflib.PdfColors.orange100),
                cellHeight: 25,
                cellAlignments: {
                  0: pw.Alignment.center,
                  1: pw.Alignment.center,
                  2: pw.Alignment.center,
                },
                headers: [
                  AppTranslations.translate('date_col', lang),
                  AppTranslations.translate('time_col', lang),
                  AppTranslations.translate('reading_mg_dl', lang),
                ],
                data: sugarReadings.map((reading) {
                  return [
                    DateFormat('d/M/yyyy', isArabic ? 'ar' : 'en').format(reading.when),
                    DateFormat('h:mm a', isArabic ? 'ar' : 'en').format(reading.when),
                    '${reading.value}',
                  ];
                }).toList(),
              ),
            pw.SizedBox(height: 24),

            // Blood Sugar Medications
            pw.Text(
              AppTranslations.translate('bs_meds_taken_title', lang),
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: pdflib.PdfColors.orange900),
              textDirection: pdfTextDirection,
            ),
            pw.SizedBox(height: 12),
            if (sugarMedsTaken.isEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.all(16),
                child: pw.Text(
                  AppTranslations.translate('no_bs_meds_taken', lang),
                  style: const pw.TextStyle(color: pdflib.PdfColors.grey700),
                  textDirection: pdfTextDirection,
                ),
              )
            else
              pw.TableHelper.fromTextArray(
                context: context,
                border: pw.TableBorder.all(color: pdflib.PdfColors.grey300),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                headerDecoration: const pw.BoxDecoration(color: pdflib.PdfColors.orange100),
                cellHeight: 25,
                cellAlignments: {
                  0: pw.Alignment.center,
                  1: pw.Alignment.center,
                  2: pw.Alignment.centerRight,
                  3: pw.Alignment.center,
                },
                headers: [
                  AppTranslations.translate('date_col', lang),
                  AppTranslations.translate('time_col', lang),
                  AppTranslations.translate('medication_name', lang),
                  AppTranslations.translate('dose', lang),
                ],
                data: sugarMedsTaken.map((log) {
                  return [
                    DateFormat('d/M/yyyy', isArabic ? 'ar' : 'en').format(log.when),
                    DateFormat('h:mm a', isArabic ? 'ar' : 'en').format(log.when),
                    log.medicationName,
                    log.dose,
                  ];
                }).toList(),
              ),
            pw.SizedBox(height: 24),

            // Disclaimer
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: pdflib.PdfColors.red50,
                border: pw.Border.all(color: pdflib.PdfColors.red200),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Text(
                AppTranslations.translate('disclaimer_text', lang),
                style: const pw.TextStyle(color: pdflib.PdfColors.red700, fontSize: 12),
                textAlign: pw.TextAlign.center,
                textDirection: pdfTextDirection,
              ),
            ),
          ];
        },
      ),
    );
  }

  Future<void> _addMedicationsPage(
    pw.Document doc,
    SettingsProvider settingsProvider,
    MedicationProvider medicationProvider,
    AdherenceProvider adherenceProvider,
    DateTime startDate,
    DateTime now,
    pw.Font arabicFont,
    pw.Font arabicFontBold,
    DateFormat dateFormat,
    String lang,
  ) async {
    final isArabic = lang == 'ar';
    final pdfTextDirection = isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr;

    final otherMedsTaken = adherenceProvider.logs
        .where((log) {
          if (!log.when.isAfter(startDate) || !log.taken) return false;
          final med = medicationProvider.items.firstWhere(
            (m) => m['name'] == log.medicationName,
            orElse: () => {},
          );
          final disease = med.isNotEmpty ? med['chronicDisease'] : null;
          return disease != 'ارتفاع ضغط الدم' && disease != 'السكري';
        })
        .toList()
      ..sort((a, b) => b.when.compareTo(a.when));

    doc.addPage(
      pw.MultiPage(
        pageFormat: pdflib.PdfPageFormat.a4,
        textDirection: pdfTextDirection,
        theme: pw.ThemeData.withFont(
          base: arabicFont,
          bold: arabicFontBold,
        ),
        build: (pw.Context context) {
          return [
            // Header
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: pdflib.PdfColors.green50,
                border: pw.Border.all(color: pdflib.PdfColors.green200),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                children: [
                  pw.Text(
                    AppTranslations.translate('other_meds_report_title_pdf', lang),
                    style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: pdflib.PdfColors.green900),
                    textDirection: pdfTextDirection,
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    settingsProvider.name,
                    style: const pw.TextStyle(fontSize: 18),
                    textDirection: pdfTextDirection,
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    '${AppTranslations.translate('period', lang)}: ${dateFormat.format(startDate)} - ${dateFormat.format(now)}',
                    style: const pw.TextStyle(color: pdflib.PdfColors.grey700),
                    textDirection: pdfTextDirection,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 24),

            // Other Medications
            pw.Text(
              AppTranslations.translate('other_meds_taken_title', lang),
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: pdflib.PdfColors.green900),
              textDirection: pdfTextDirection,
            ),
            pw.SizedBox(height: 12),
            if (otherMedsTaken.isEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.all(16),
                child: pw.Text(
                  AppTranslations.translate('no_other_meds_taken', lang),
                  style: const pw.TextStyle(color: pdflib.PdfColors.grey700),
                  textDirection: pdfTextDirection,
                ),
              )
            else
              pw.TableHelper.fromTextArray(
                context: context,
                border: pw.TableBorder.all(color: pdflib.PdfColors.grey300),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                headerDecoration: const pw.BoxDecoration(color: pdflib.PdfColors.green100),
                cellHeight: 25,
                cellAlignments: {
                  0: pw.Alignment.center,
                  1: pw.Alignment.center,
                  2: pw.Alignment.centerRight,
                  3: pw.Alignment.center,
                  4: pw.Alignment.centerRight,
                },
                headers: [
                  AppTranslations.translate('date_col', lang),
                  AppTranslations.translate('time_col', lang),
                  AppTranslations.translate('medication_name', lang),
                  AppTranslations.translate('dose', lang),
                  AppTranslations.translate('medication_type_col', lang),
                ],
                data: otherMedsTaken.map((log) {
                  final med = medicationProvider.items.firstWhere(
                    (m) => m['name'] == log.medicationName,
                    orElse: () => {},
                  );
                  final disease = med.isNotEmpty && med['chronicDisease'] != null
                      ? med['chronicDisease']
                      : AppTranslations.translate('no_medication_type', lang);
                  return [
                    DateFormat('d/M/yyyy', isArabic ? 'ar' : 'en').format(log.when),
                    DateFormat('h:mm a', isArabic ? 'ar' : 'en').format(log.when),
                    log.medicationName,
                    log.dose,
                    _getMedicationTypeText(disease, lang),
                  ];
                }).toList(),
              ),
            pw.SizedBox(height: 24),

            // Disclaimer
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: pdflib.PdfColors.red50,
                border: pw.Border.all(color: pdflib.PdfColors.red200),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Text(
                AppTranslations.translate('disclaimer_text', lang),
                style: const pw.TextStyle(color: pdflib.PdfColors.red700, fontSize: 12),
                textAlign: pw.TextAlign.center,
                textDirection: pdfTextDirection,
              ),
            ),
          ];
        },
      ),
    );
  }
}




