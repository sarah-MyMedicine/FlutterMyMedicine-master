import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/medication_provider.dart';
import '../providers/adherence_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/blood_pressure_provider.dart';
import '../providers/blood_sugar_provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pdf/pdf.dart';
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

  @override
  Widget build(BuildContext context) {
    if (!_isLocaleInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final medicationProvider = Provider.of<MedicationProvider>(context);
    final adherenceProvider = Provider.of<AdherenceProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final bloodPressureProvider = Provider.of<BloodPressureProvider>(context);
    final bloodSugarProvider = Provider.of<BloodSugarProvider>(context);
    
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: _selectedDays));
    final dateFormat = DateFormat('d MMMM yyyy', 'ar');
    
    final genderText = settingsProvider.gender == null 
        ? 'الجنس: غير محدد' 
        : 'الجنس: ${settingsProvider.gender == PatientGender.male ? 'ذكر' : 'أنثى'}';
    
    final takenDoses = adherenceProvider.logs
        .where((log) => log.when.isAfter(startDate) && log.taken)
        .toList();
    
    final bloodPressureEnabled = settingsProvider.chronicDiseases.contains('ارتفاع ضغط الدم');
    final bloodSugarEnabled = settingsProvider.chronicDiseases.contains('السكري');
    
    final bloodPressureReadings = bloodPressureEnabled
        ? bloodPressureProvider.readings.where((r) => r.when.isAfter(startDate)).toList()
        : <BloodPressureReading>[];
    
    final bloodSugarReadings = bloodSugarEnabled
        ? bloodSugarProvider.readings.where((r) => r.when.isAfter(startDate)).toList()
        : <BloodSugarReading>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('تقرير صحي'),
        actions: [
          PopupMenuButton<int>(
            initialValue: _selectedDays,
            child: Chip(
              label: Text('آخر $_selectedDays ${_selectedDays == 7 ? 'أيام' : _selectedDays == 30 ? 'يوم' : 'يوم'}'),
            ),
            onSelected: (value) {
              setState(() {
                _selectedDays = value;
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<int>>[
              const PopupMenuItem<int>(value: 7, child: Text('آخر 7 أيام')),
              const PopupMenuItem<int>(value: 30, child: Text('آخر 30 يوم')),
              const PopupMenuItem<int>(value: 90, child: Text('آخر 90 يوم')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'طباعة / حفظ كـ PDF',
            onPressed: () async {
              await _generatePdf(
                context,
                settingsProvider,
                takenDoses,
                medicationProvider,
                bloodPressureReadings,
                bloodSugarReadings,
                startDate,
                now,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(

          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        'تقرير صحي',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(settingsProvider.name, style: const TextStyle(fontSize: 18)),
                      Text(genderText, style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 8),
                      Text(
                        'الفترة: ${dateFormat.format(startDate)} - ${dateFormat.format(now)}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Chart/Table View
              _buildHealthChart(
                takenDoses,
                medicationProvider,
                bloodPressureReadings,
                bloodSugarReadings,
                bloodPressureEnabled,
                bloodSugarEnabled,
              ),
              
              const SizedBox(height: 24),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: const Text(
                  'تنويه هام: تطبيق دوائي لا يبديل استشارة الطبيب وتأكد دائماً أن جرعاتك محددة من قبل الطبيب أو الصيدلي.',
                  style: TextStyle(color: Colors.red, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
      ),
    );
  }

  Widget _buildHealthChart(
    List<AdherenceLog> takenDoses,
    MedicationProvider medicationProvider,
    List<BloodPressureReading> bloodPressureReadings,
    List<BloodSugarReading> bloodSugarReadings,
    bool bloodPressureEnabled,
    bool bloodSugarEnabled,
  ) {
    // Combine all events into a single timeline
    final Map<DateTime, Map<String, dynamic>> timeline = {};

    // Add medication doses
    for (var dose in takenDoses) {
      final key = DateTime(dose.when.year, dose.when.month, dose.when.day, dose.when.hour, dose.when.minute);
      if (!timeline.containsKey(key)) {
        timeline[key] = {'medicines': [], 'bloodPressure': null, 'bloodSugar': null};
      }
      final medication = medicationProvider.items.firstWhere(
        (m) => m['name'] == dose.medicationName,
        orElse: () => {'name': dose.medicationName, 'dose': dose.dose},
      );
      timeline[key]!['medicines'].add('${medication['name']} (${medication['dose']})');
    }

    // Add blood pressure readings
    if (bloodPressureEnabled) {
      for (var reading in bloodPressureReadings) {
        final key = DateTime(reading.when.year, reading.when.month, reading.when.day, reading.when.hour, reading.when.minute);
        if (!timeline.containsKey(key)) {
          timeline[key] = {'medicines': [], 'bloodPressure': null, 'bloodSugar': null};
        }
        timeline[key]!['bloodPressure'] = '${reading.systolic}/${reading.diastolic}';
      }
    }

    // Add blood sugar readings
    if (bloodSugarEnabled) {
      for (var reading in bloodSugarReadings) {
        final key = DateTime(reading.when.year, reading.when.month, reading.when.day, reading.when.hour, reading.when.minute);
        if (!timeline.containsKey(key)) {
          timeline[key] = {'medicines': [], 'bloodPressure': null, 'bloodSugar': null};
        }
        timeline[key]!['bloodSugar'] = '${reading.value}';
      }
    }

    if (timeline.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'لا توجد بيانات صحية في هذه الفترة',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    // Sort timeline by date
    final sortedKeys = timeline.keys.toList()..sort((a, b) => b.compareTo(a));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(Colors.teal.shade50),
        border: TableBorder.all(color: Colors.grey.shade300),
        columns: [
          const DataColumn(
            label: Text(
              'التاريخ والوقت',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const DataColumn(
            label: Text(
              'الدواء المأخوذ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          if (bloodPressureEnabled)
            const DataColumn(
              label: Text(
                'ضغط الدم',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          if (bloodSugarEnabled)
            const DataColumn(
              label: Text(
                'سكر الدم',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
        ],
        rows: sortedKeys.map((dateTime) {
          final data = timeline[dateTime]!;
          final dateFormat = DateFormat('d MMM yyyy', 'ar');
          final timeFormat = DateFormat('h:mm a', 'ar');

          return DataRow(
            cells: [
              DataCell(
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateFormat.format(dateTime),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      timeFormat.format(dateTime),
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              DataCell(
                SizedBox(
                  width: 200,
                  child: data['medicines'].isEmpty
                      ? const Text('-', style: TextStyle(color: Colors.grey))
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: (data['medicines'] as List).map<Widget>((med) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                med,
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                        ),
                ),
              ),
              if (bloodPressureEnabled)
                DataCell(
                  Text(
                    data['bloodPressure'] ?? '-',
                    style: TextStyle(
                      fontSize: 12,
                      color: data['bloodPressure'] != null ? Colors.black : Colors.grey,
                    ),
                  ),
                ),
              if (bloodSugarEnabled)
                DataCell(
                  Text(
                    data['bloodSugar'] != null ? '${data['bloodSugar']} mg/dL' : '-',
                    style: TextStyle(
                      fontSize: 12,
                      color: data['bloodSugar'] != null ? Colors.black : Colors.grey,
                    ),
                  ),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Future<void> _generatePdf(
    BuildContext context,
    SettingsProvider settingsProvider,
    List<AdherenceLog> takenDoses,
    MedicationProvider medicationProvider,
    List<BloodPressureReading> bloodPressureReadings,
    List<BloodSugarReading> bloodSugarReadings,
    DateTime startDate,
    DateTime now,
  ) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('d MMMM yyyy', 'ar');
    
    final genderText = settingsProvider.gender == null 
        ? 'الجنس: غير محدد' 
        : 'الجنس: ${settingsProvider.gender == PatientGender.male ? 'ذكر' : 'أنثى'}';
    
    final bloodPressureEnabled = settingsProvider.chronicDiseases.contains('ارتفاع ضغط الدم');
    final bloodSugarEnabled = settingsProvider.chronicDiseases.contains('السكري');

    // Load Arabic font
    final arabicFont = await PdfGoogleFonts.cairoRegular();
    final arabicFontBold = await PdfGoogleFonts.cairoBold();

    // Build timeline similar to UI
    final Map<DateTime, Map<String, dynamic>> timeline = {};

    for (var dose in takenDoses) {
      final key = DateTime(dose.when.year, dose.when.month, dose.when.day, dose.when.hour, dose.when.minute);
      if (!timeline.containsKey(key)) {
        timeline[key] = {'medicines': [], 'bloodPressure': null, 'bloodSugar': null};
      }
      final medication = medicationProvider.items.firstWhere(
        (m) => m['name'] == dose.medicationName,
        orElse: () => {'name': dose.medicationName, 'dose': dose.dose},
      );
      timeline[key]!['medicines'].add('${medication['name']} (${medication['dose']})');
    }

    if (bloodPressureEnabled) {
      for (var reading in bloodPressureReadings) {
        final key = DateTime(reading.when.year, reading.when.month, reading.when.day, reading.when.hour, reading.when.minute);
        if (!timeline.containsKey(key)) {
          timeline[key] = {'medicines': [], 'bloodPressure': null, 'bloodSugar': null};
        }
        timeline[key]!['bloodPressure'] = '${reading.systolic}/${reading.diastolic}';
      }
    }

    if (bloodSugarEnabled) {
      for (var reading in bloodSugarReadings) {
        final key = DateTime(reading.when.year, reading.when.month, reading.when.day, reading.when.hour, reading.when.minute);
        if (!timeline.containsKey(key)) {
          timeline[key] = {'medicines': [], 'bloodPressure': null, 'bloodSugar': null};
        }
        timeline[key]!['bloodSugar'] = '${reading.value}';
      }
    }

    final sortedKeys = timeline.keys.toList()..sort((a, b) => b.compareTo(a));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(
          base: arabicFont,
          bold: arabicFontBold,
        ),
        build: (pw.Context pdfContext) {
          return [
            // Header
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                children: [
                  pw.Text(
                    'تقرير صحي',
                    style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                    textDirection: pw.TextDirection.rtl,
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    settingsProvider.name,
                    style: const pw.TextStyle(fontSize: 18),
                    textDirection: pw.TextDirection.rtl,
                  ),
                  pw.Text(
                    genderText,
                    style: const pw.TextStyle(color: PdfColors.grey700),
                    textDirection: pw.TextDirection.rtl,
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'الفترة: ${dateFormat.format(startDate)} - ${dateFormat.format(now)}',
                    style: const pw.TextStyle(color: PdfColors.grey700),
                    textDirection: pw.TextDirection.rtl,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 24),

            // Health Data Table
            if (timeline.isEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.all(24),
                child: pw.Text(
                  'لا توجد بيانات صحية في هذه الفترة',
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 16),
                  textDirection: pw.TextDirection.rtl,
                ),
              )
            else
              pw.TableHelper.fromTextArray(
                context: pdfContext,
                border: pw.TableBorder.all(color: PdfColors.grey300),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
                cellHeight: 30,
                cellAlignments: {
                  0: pw.Alignment.center,
                  1: pw.Alignment.centerRight,
                  if (bloodPressureEnabled) 2: pw.Alignment.center,
                  if (bloodSugarEnabled) (bloodPressureEnabled ? 3 : 2): pw.Alignment.center,
                },
                headers: [
                  'التاريخ والوقت',
                  'الدواء المأخوذ',
                  if (bloodPressureEnabled) 'ضغط الدم',
                  if (bloodSugarEnabled) 'سكر الدم',
                ],
                data: sortedKeys.map((dateTime) {
                  final data = timeline[dateTime]!;
                  final dateStr = DateFormat('d MMM yyyy', 'ar').format(dateTime);
                  final timeStr = DateFormat('h:mm a', 'ar').format(dateTime);
                  final medicines = (data['medicines'] as List).isEmpty
                      ? '-'
                      : (data['medicines'] as List).join('\\n');

                  return [
                    '$dateStr\\n$timeStr',
                    medicines,
                    if (bloodPressureEnabled) data['bloodPressure'] ?? '-',
                    if (bloodSugarEnabled) data['bloodSugar'] != null ? '${data['bloodSugar']} mg/dL' : '-',
                  ];
                }).toList(),
              ),

            pw.SizedBox(height: 24),

            // Disclaimer
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.red50,
                border: pw.Border.all(color: PdfColors.red200),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Text(
                'تنويه هام: تطبيق دوائي لا يبديل استشارة الطبيب وتأكد دائماً أن جرعاتك محددة من قبل الطبيب أو الصيدلي.',
                style: const pw.TextStyle(color: PdfColors.red700, fontSize: 14),
                textAlign: pw.TextAlign.center,
                textDirection: pw.TextDirection.rtl,
              ),
            ),
          ];
        },
      ),
    );

    // Show print/save dialog
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'تقرير_صحي_${DateFormat('yyyy-MM-dd').format(now)}.pdf',
    );
  }
}
