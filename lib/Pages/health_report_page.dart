import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/medication_provider.dart';
import '../providers/adherence_provider.dart';
import '../providers/settings_provider.dart';
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
    
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: _selectedDays));
    final dateFormat = DateFormat('d MMMM yyyy', 'ar');
    
    final genderText = settingsProvider.gender == null 
        ? 'الجنس: غير محدد' 
        : 'الجنس: ${settingsProvider.gender == PatientGender.male ? 'ذكر' : 'أنثى'}';
    
    final takenDoses = adherenceProvider.logs
        .where((log) => log.when.isAfter(startDate) && log.taken)
        .toList();

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
              
              const Text(
                'سجل الجرعات المأخوذة',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.right,
              ),
              const Divider(),
              const SizedBox(height: 8),
              
              takenDoses.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'لا يوجد سجل للجرعات في هذه الفترة',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    )
                  : Column(
                      children: _groupDosesByDate(takenDoses, medicationProvider),
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

  List<Widget> _groupDosesByDate(List<AdherenceLog> doses, MedicationProvider medProvider) {
    final Map<String, List<AdherenceLog>> groupedDoses = {};
    final dateFormat = DateFormat('EEEE، d MMMM', 'ar');
    final timeFormat = DateFormat('h:mm a', 'ar');

    for (var dose in doses) {
      final dateKey = dateFormat.format(dose.when);
      if (!groupedDoses.containsKey(dateKey)) {
        groupedDoses[dateKey] = [];
      }
      groupedDoses[dateKey]!.add(dose);
    }

    final List<Widget> widgets = [];
    groupedDoses.forEach((date, dosesOnDate) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(
            date,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      );

      for (var dose in dosesOnDate) {
        final medication = medProvider.items.firstWhere(
          (m) => m['name'] == dose.medicationName,
          orElse: () => {'name': dose.medicationName, 'dose': dose.dose},
        );
        
        widgets.add(
          Card(
            margin: const EdgeInsets.only(bottom: 4),
            child: ListTile(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(medication['name'] ?? ''),
                  Text(
                    timeFormat.format(dose.when),
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
              subtitle: Text(medication['dose'] ?? ''),
            ),
          ),
        );
      }
    });

    return widgets;
  }

  Future<void> _generatePdf(
    BuildContext context,
    SettingsProvider settingsProvider,
    List<AdherenceLog> takenDoses,
    MedicationProvider medicationProvider,
    DateTime startDate,
    DateTime now,
  ) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('d MMMM yyyy', 'ar');
    final timeFormat = DateFormat('h:mm a', 'ar');
    
    final genderText = settingsProvider.gender == null 
        ? 'الجنس: غير محدد' 
        : 'الجنس: ${settingsProvider.gender == PatientGender.male ? 'ذكر' : 'أنثى'}';

    // Load Arabic font
    final arabicFont = await PdfGoogleFonts.cairoRegular();
    final arabicFontBold = await PdfGoogleFonts.cairoBold();

    // Group doses by date
    final Map<String, List<AdherenceLog>> groupedDoses = {};
    for (var dose in takenDoses) {
      final dateKey = dateFormat.format(dose.when);
      if (!groupedDoses.containsKey(dateKey)) {
        groupedDoses[dateKey] = [];
      }
      groupedDoses[dateKey]!.add(dose);
    }

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

            // Taken Doses Section
            pw.Text(
              'سجل الجرعات المأخوذة',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
              textDirection: pw.TextDirection.rtl,
            ),
            pw.Divider(),
            pw.SizedBox(height: 8),

            if (takenDoses.isEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.all(24),
                child: pw.Text(
                  'لا يوجد سجل للجرعات في هذه الفترة',
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 16),
                  textDirection: pw.TextDirection.rtl,
                ),
              )
            else
              ...groupedDoses.entries.expand((entry) {
                final date = entry.key;
                final dosesOnDate = entry.value;
                
                return [
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 16, bottom: 8),
                    child: pw.Text(
                      date,
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                      textDirection: pw.TextDirection.rtl,
                    ),
                  ),
                  ...dosesOnDate.map((dose) {
                    final medication = medicationProvider.items.firstWhere(
                      (m) => m['name'] == dose.medicationName,
                      orElse: () => {'name': dose.medicationName, 'dose': dose.dose},
                    );
                    
                    return pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 4),
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                timeFormat.format(dose.when),
                                style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 14),
                              ),
                              pw.Text(
                                medication['name'] ?? '',
                                textDirection: pw.TextDirection.rtl,
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            medication['dose'] ?? '',
                            style: const pw.TextStyle(fontSize: 12),
                            textDirection: pw.TextDirection.rtl,
                          ),
                        ],
                      ),
                    );
                  }),
                ];
              }),

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
