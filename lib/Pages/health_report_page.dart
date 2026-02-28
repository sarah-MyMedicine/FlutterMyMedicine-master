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
    
    final bloodPressureEnabled = settingsProvider.chronicDiseases.contains('ارتفاع ضغط الدم');
    final bloodSugarEnabled = settingsProvider.chronicDiseases.contains('السكري');

    return Scaffold(
      backgroundColor: Colors.grey[50],
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
              await _showExportDialog(
                context,
                settingsProvider,
                medicationProvider,
                adherenceProvider,
                bloodPressureProvider,
                bloodSugarProvider,
                startDate,
                now,
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
              gradient: const LinearGradient(
                colors: [Color(0xFF36BBA0), Color(0xFF5DABA8)],
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
                  'تقرير ${settingsProvider.name}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'الفترة: ${dateFormat.format(startDate)} - ${dateFormat.format(now)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 16),
                // Tab buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildTabButton('ضغط الدم', 0),
                    _buildTabButton('سكر الدم', 1),
                    _buildTabButton('الأدوية', 2),
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
                    alignment: Alignment.centerRight,
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _selectedTab == index;
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
            color: isSelected ? const Color(0xFF36BBA0) : Colors.white,
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
  ) {
    switch (_selectedTab) {
      case 0:
        return _buildBloodPressureTab(
          medicationProvider,
          adherenceProvider,
          bloodPressureProvider,
          bloodPressureEnabled,
          startDate,
        );
      case 1:
        return _buildBloodSugarTab(
          medicationProvider,
          adherenceProvider,
          bloodSugarProvider,
          bloodSugarEnabled,
          startDate,
        );
      case 2:
        return _buildMedicationsTab(
          medicationProvider,
          adherenceProvider,
          startDate,
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
  ) {
    if (!bloodPressureEnabled) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'ضغط الدم غير مفعل في الأمراض المزمنة',
            style: TextStyle(color: Colors.grey, fontSize: 16),
            textAlign: TextAlign.center,
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
                  const Row(
                    children: [
                      Icon(Icons.favorite, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'قراءات ضغط الدم',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (bpReadings.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'لا توجد قراءات ضغط دم في هذه الفترة',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(Colors.red.shade50),
                        border: TableBorder.all(color: Colors.grey.shade300),
                        columns: const [
                          DataColumn(label: Text('التاريخ', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('الوقت', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('الانقباضي', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('الانبساطي', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: bpReadings.map((reading) {
                          final dateFormat = DateFormat('d/M/yyyy', 'ar');
                          final timeFormat = DateFormat('h:mm a', 'ar');
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
                  const Row(
                    children: [
                      Icon(Icons.medication, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'أدوية ضغط الدم المأخوذة',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (bpMedsTaken.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'لا توجد أدوية ضغط دم مأخوذة في هذه الفترة',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(Colors.blue.shade50),
                        border: TableBorder.all(color: Colors.grey.shade300),
                        columns: const [
                          DataColumn(label: Text('التاريخ', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('الوقت', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('اسم الدواء', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('الجرعة', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('المرض', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: bpMedsTaken.map((log) {
                          final dateFormat = DateFormat('d/M/yyyy', 'ar');
                          final timeFormat = DateFormat('h:mm a', 'ar');
                          return DataRow(
                            cells: [
                              DataCell(Text(dateFormat.format(log.when))),
                              DataCell(Text(timeFormat.format(log.when))),
                              DataCell(Text(log.medicationName, style: const TextStyle(fontWeight: FontWeight.bold))),
                              DataCell(Text(log.dose)),
                              DataCell(Text('ارتفاع ضغط الدم', style: TextStyle(fontSize: 11, color: Colors.red.shade700))),
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
  ) {
    if (!bloodSugarEnabled) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'سكر الدم غير مفعل في الأمراض المزمنة',
            style: TextStyle(color: Colors.grey, fontSize: 16),
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
                  const Row(
                    children: [
                      Icon(Icons.water_drop, color: Colors.orange, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'قراءات سكر الدم',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (sugarReadings.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'لا توجد قراءات سكر دم في هذه الفترة',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(Colors.orange.shade50),
                        border: TableBorder.all(color: Colors.grey.shade300),
                        columns: const [
                          DataColumn(label: Text('التاريخ', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('الوقت', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('القراءة (mg/dL)', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: sugarReadings.map((reading) {
                          final dateFormat = DateFormat('d/M/yyyy', 'ar');
                          final timeFormat = DateFormat('h:mm a', 'ar');
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
                  const Row(
                    children: [
                      Icon(Icons.medication, color: Colors.orange, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'أدوية سكر الدم المأخوذة',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (sugarMedsTaken.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'لا توجد أدوية سكر دم مأخوذة في هذه الفترة',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(Colors.orange.shade50),
                        border: TableBorder.all(color: Colors.grey.shade300),
                        columns: const [
                          DataColumn(label: Text('التاريخ', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('الوقت', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('اسم الدواء', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('الجرعة', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('المرض', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: sugarMedsTaken.map((log) {
                          final dateFormat = DateFormat('d/M/yyyy', 'ar');
                          final timeFormat = DateFormat('h:mm a', 'ar');
                          return DataRow(
                            cells: [
                              DataCell(Text(dateFormat.format(log.when))),
                              DataCell(Text(timeFormat.format(log.when))),
                              DataCell(Text(log.medicationName, style: const TextStyle(fontWeight: FontWeight.bold))),
                              DataCell(Text(log.dose)),
                              DataCell(Text('السكري', style: TextStyle(fontSize: 11, color: Colors.orange.shade700))),
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
              const Row(
                children: [
                  Icon(Icons.medication_liquid, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'الأدوية الأخرى المأخوذة',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (otherMedsTaken.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'لا توجد أدوية أخرى مأخوذة في هذه الفترة',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(Colors.green.shade50),
                    border: TableBorder.all(color: Colors.grey.shade300),
                    columns: const [
                      DataColumn(label: Text('التاريخ', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('الوقت', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('اسم الدواء', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('الجرعة', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('المرض المزمن', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: otherMedsTaken.map((log) {
                      final dateFormat = DateFormat('d/M/yyyy', 'ar');
                      final timeFormat = DateFormat('h:mm a', 'ar');
                      final med = medicationProvider.items.firstWhere(
                        (m) => m['name'] == log.medicationName,
                        orElse: () => {},
                      );
                      final disease = med.isNotEmpty && med['chronicDisease'] != null 
                          ? med['chronicDisease'] 
                          : 'لا يوجد';
                      return DataRow(
                        cells: [
                          DataCell(Text(dateFormat.format(log.when))),
                          DataCell(Text(timeFormat.format(log.when))),
                          DataCell(Text(log.medicationName, style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text(log.dose)),
                          DataCell(Text(disease!, style: TextStyle(fontSize: 11, color: Colors.green.shade700))),
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
  ) async {
    final bloodPressureEnabled = settingsProvider.chronicDiseases.contains('ارتفاع ضغط الدم');
    final bloodSugarEnabled = settingsProvider.chronicDiseases.contains('السكري');

    return showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('تصدير التقرير'),
          content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('ما البيانات التي تريد تصديرها؟'),
                const SizedBox(height: 16),
                if (bloodPressureEnabled)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.favorite),
                    label: const Text('ضغط الدم والأدوية'),
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
                      );
                    },
                  ),
                if (bloodPressureEnabled) const SizedBox(height: 8),
                if (bloodSugarEnabled)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.water_drop),
                    label: const Text('سكر الدم والأدوية'),
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
                      );
                    },
                  ),
                if (bloodSugarEnabled) const SizedBox(height: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.medication_liquid),
                  label: const Text('الأدوية الأخرى'),
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
                    );
                  },
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.list_alt),
                  label: const Text('تصدير الكل'),
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
                    );
                  },
                ),
              ],
            ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
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
  ) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('d MMMM yyyy', 'ar');
    
    final bloodPressureEnabled = settingsProvider.chronicDiseases.contains('ارتفاع ضغط الدم');
    final bloodSugarEnabled = settingsProvider.chronicDiseases.contains('السكري');

    // Load Arabic font
    final arabicFont = await PdfGoogleFonts.cairoRegular();
    final arabicFontBold = await PdfGoogleFonts.cairoBold();

    if (exportType == 'all') {
      // Export all three types in separate pages
      if (bloodPressureEnabled) {
        await _addBloodPressurePage(pdf, settingsProvider, medicationProvider, adherenceProvider, bloodPressureProvider, startDate, now, arabicFont, arabicFontBold, dateFormat);
      }
      if (bloodSugarEnabled) {
        await _addBloodSugarPage(pdf, settingsProvider, medicationProvider, adherenceProvider, bloodSugarProvider, startDate, now, arabicFont, arabicFontBold, dateFormat);
      }
      await _addMedicationsPage(pdf, settingsProvider, medicationProvider, adherenceProvider, startDate, now, arabicFont, arabicFontBold, dateFormat);
    } else if (exportType == 'bloodPressure') {
      await _addBloodPressurePage(pdf, settingsProvider, medicationProvider, adherenceProvider, bloodPressureProvider, startDate, now, arabicFont, arabicFontBold, dateFormat);
    } else if (exportType == 'bloodSugar') {
      await _addBloodSugarPage(pdf, settingsProvider, medicationProvider, adherenceProvider, bloodSugarProvider, startDate, now, arabicFont, arabicFontBold, dateFormat);
    } else if (exportType == 'medications') {
      await _addMedicationsPage(pdf, settingsProvider, medicationProvider, adherenceProvider, startDate, now, arabicFont, arabicFontBold, dateFormat);
    }

    // Show print/save dialog
    String fileName = 'تقرير_صحي';
    if (exportType == 'bloodPressure') fileName = 'تقرير_ضغط_الدم';
    else if (exportType == 'bloodSugar') fileName = 'تقرير_سكر_الدم';
    else if (exportType == 'medications') fileName = 'تقرير_الأدوية';
    
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: '${fileName}_${DateFormat('yyyy-MM-dd').format(now)}.pdf',
    );
  }

  Future<void> _addBloodPressurePage(
    pw.Document pdf,
    SettingsProvider settingsProvider,
    MedicationProvider medicationProvider,
    AdherenceProvider adherenceProvider,
    BloodPressureProvider bloodPressureProvider,
    DateTime startDate,
    DateTime now,
    pw.Font arabicFont,
    pw.Font arabicFontBold,
    DateFormat dateFormat,
  ) async {
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

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
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
                color: PdfColors.red50,
                border: pw.Border.all(color: PdfColors.red200),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                children: [
                  pw.Text(
                    'تقرير ضغط الدم',
                    style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.red900),
                    textDirection: pw.TextDirection.rtl,
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    settingsProvider.name,
                    style: const pw.TextStyle(fontSize: 18),
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

            // Blood Pressure Readings
            pw.Text(
              'قراءات ضغط الدم',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.red900),
              textDirection: pw.TextDirection.rtl,
            ),
            pw.SizedBox(height: 12),
            if (bpReadings.isEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.all(16),
                child: pw.Text(
                  'لا توجد قراءات ضغط دم في هذه الفترة',
                  style: const pw.TextStyle(color: PdfColors.grey700),
                  textDirection: pw.TextDirection.rtl,
                ),
              )
            else
              pw.TableHelper.fromTextArray(
                context: context,
                border: pw.TableBorder.all(color: PdfColors.grey300),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.red100),
                cellHeight: 25,
                cellAlignments: {
                  0: pw.Alignment.center,
                  1: pw.Alignment.center,
                  2: pw.Alignment.center,
                  3: pw.Alignment.center,
                },
                headers: ['التاريخ', 'الوقت', 'الانقباضي', 'الانبساطي'],
                data: bpReadings.map((reading) {
                  return [
                    DateFormat('d/M/yyyy', 'ar').format(reading.when),
                    DateFormat('h:mm a', 'ar').format(reading.when),
                    '${reading.systolic}',
                    '${reading.diastolic}',
                  ];
                }).toList(),
              ),
            pw.SizedBox(height: 24),

            // Blood Pressure Medications
            pw.Text(
              'أدوية ضغط الدم المأخوذة',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
              textDirection: pw.TextDirection.rtl,
            ),
            pw.SizedBox(height: 12),
            if (bpMedsTaken.isEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.all(16),
                child: pw.Text(
                  'لا توجد أدوية ضغط دم مأخوذة في هذه الفترة',
                  style: const pw.TextStyle(color: PdfColors.grey700),
                  textDirection: pw.TextDirection.rtl,
                ),
              )
            else
              pw.TableHelper.fromTextArray(
                context: context,
                border: pw.TableBorder.all(color: PdfColors.grey300),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blue100),
                cellHeight: 25,
                cellAlignments: {
                  0: pw.Alignment.center,
                  1: pw.Alignment.center,
                  2: pw.Alignment.centerRight,
                  3: pw.Alignment.center,
                },
                headers: ['التاريخ', 'الوقت', 'اسم الدواء', 'الجرعة'],
                data: bpMedsTaken.map((log) {
                  return [
                    DateFormat('d/M/yyyy', 'ar').format(log.when),
                    DateFormat('h:mm a', 'ar').format(log.when),
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
                color: PdfColors.red50,
                border: pw.Border.all(color: PdfColors.red200),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Text(
                'تنويه هام: تطبيق دوائي لا يبديل استشارة الطبيب وتأكد دائماً أن جرعاتك محددة من قبل الطبيب أو الصيدلي.',
                style: const pw.TextStyle(color: PdfColors.red700, fontSize: 12),
                textAlign: pw.TextAlign.center,
                textDirection: pw.TextDirection.rtl,
              ),
            ),
          ];
        },
      ),
    );
  }

  Future<void> _addBloodSugarPage(
    pw.Document pdf,
    SettingsProvider settingsProvider,
    MedicationProvider medicationProvider,
    AdherenceProvider adherenceProvider,
    BloodSugarProvider bloodSugarProvider,
    DateTime startDate,
    DateTime now,
    pw.Font arabicFont,
    pw.Font arabicFontBold,
    DateFormat dateFormat,
  ) async {
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

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
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
                color: PdfColors.orange50,
                border: pw.Border.all(color: PdfColors.orange200),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                children: [
                  pw.Text(
                    'تقرير سكر الدم',
                    style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.orange900),
                    textDirection: pw.TextDirection.rtl,
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    settingsProvider.name,
                    style: const pw.TextStyle(fontSize: 18),
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

            // Blood Sugar Readings
            pw.Text(
              'قراءات سكر الدم',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.orange900),
              textDirection: pw.TextDirection.rtl,
            ),
            pw.SizedBox(height: 12),
            if (sugarReadings.isEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.all(16),
                child: pw.Text(
                  'لا توجد قراءات سكر دم في هذه الفترة',
                  style: const pw.TextStyle(color: PdfColors.grey700),
                  textDirection: pw.TextDirection.rtl,
                ),
              )
            else
              pw.TableHelper.fromTextArray(
                context: context,
                border: pw.TableBorder.all(color: PdfColors.grey300),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.orange100),
                cellHeight: 25,
                cellAlignments: {
                  0: pw.Alignment.center,
                  1: pw.Alignment.center,
                  2: pw.Alignment.center,
                },
                headers: ['التاريخ', 'الوقت', 'القراءة (mg/dL)'],
                data: sugarReadings.map((reading) {
                  return [
                    DateFormat('d/M/yyyy', 'ar').format(reading.when),
                    DateFormat('h:mm a', 'ar').format(reading.when),
                    '${reading.value}',
                  ];
                }).toList(),
              ),
            pw.SizedBox(height: 24),

            // Blood Sugar Medications
            pw.Text(
              'أدوية سكر الدم المأخوذة',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.orange900),
              textDirection: pw.TextDirection.rtl,
            ),
            pw.SizedBox(height: 12),
            if (sugarMedsTaken.isEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.all(16),
                child: pw.Text(
                  'لا توجد أدوية سكر دم مأخوذة في هذه الفترة',
                  style: const pw.TextStyle(color: PdfColors.grey700),
                  textDirection: pw.TextDirection.rtl,
                ),
              )
            else
              pw.TableHelper.fromTextArray(
                context: context,
                border: pw.TableBorder.all(color: PdfColors.grey300),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.orange100),
                cellHeight: 25,
                cellAlignments: {
                  0: pw.Alignment.center,
                  1: pw.Alignment.center,
                  2: pw.Alignment.centerRight,
                  3: pw.Alignment.center,
                },
                headers: ['التاريخ', 'الوقت', 'اسم الدواء', 'الجرعة'],
                data: sugarMedsTaken.map((log) {
                  return [
                    DateFormat('d/M/yyyy', 'ar').format(log.when),
                    DateFormat('h:mm a', 'ar').format(log.when),
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
                color: PdfColors.red50,
                border: pw.Border.all(color: PdfColors.red200),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Text(
                'تنويه هام: تطبيق دوائي لا يبديل استشارة الطبيب وتأكد دائماً أن جرعاتك محددة من قبل الطبيب أو الصيدلي.',
                style: const pw.TextStyle(color: PdfColors.red700, fontSize: 12),
                textAlign: pw.TextAlign.center,
                textDirection: pw.TextDirection.rtl,
              ),
            ),
          ];
        },
      ),
    );
  }

  Future<void> _addMedicationsPage(
    pw.Document pdf,
    SettingsProvider settingsProvider,
    MedicationProvider medicationProvider,
    AdherenceProvider adherenceProvider,
    DateTime startDate,
    DateTime now,
    pw.Font arabicFont,
    pw.Font arabicFontBold,
    DateFormat dateFormat,
  ) async {
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

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
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
                color: PdfColors.green50,
                border: pw.Border.all(color: PdfColors.green200),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                children: [
                  pw.Text(
                    'تقرير الأدوية الأخرى',
                    style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.green900),
                    textDirection: pw.TextDirection.rtl,
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    settingsProvider.name,
                    style: const pw.TextStyle(fontSize: 18),
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

            // Other Medications
            pw.Text(
              'الأدوية الأخرى المأخوذة',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.green900),
              textDirection: pw.TextDirection.rtl,
            ),
            pw.SizedBox(height: 12),
            if (otherMedsTaken.isEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.all(16),
                child: pw.Text(
                  'لا توجد أدوية أخرى مأخوذة في هذه الفترة',
                  style: const pw.TextStyle(color: PdfColors.grey700),
                  textDirection: pw.TextDirection.rtl,
                ),
              )
            else
              pw.TableHelper.fromTextArray(
                context: context,
                border: pw.TableBorder.all(color: PdfColors.grey300),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.green100),
                cellHeight: 25,
                cellAlignments: {
                  0: pw.Alignment.center,
                  1: pw.Alignment.center,
                  2: pw.Alignment.centerRight,
                  3: pw.Alignment.center,
                  4: pw.Alignment.centerRight,
                },
                headers: ['التاريخ', 'الوقت', 'اسم الدواء', 'الجرعة', 'المرض المزمن'],
                data: otherMedsTaken.map((log) {
                  final med = medicationProvider.items.firstWhere(
                    (m) => m['name'] == log.medicationName,
                    orElse: () => {},
                  );
                  final disease = med.isNotEmpty && med['chronicDisease'] != null
                      ? med['chronicDisease']
                      : 'لا يوجد';
                  return [
                    DateFormat('d/M/yyyy', 'ar').format(log.when),
                    DateFormat('h:mm a', 'ar').format(log.when),
                    log.medicationName,
                    log.dose,
                    disease!,
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
                style: const pw.TextStyle(color: PdfColors.red700, fontSize: 12),
                textAlign: pw.TextAlign.center,
                textDirection: pw.TextDirection.rtl,
              ),
            ),
          ];
        },
      ),
    );
  }
}
