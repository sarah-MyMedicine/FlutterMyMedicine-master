import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../providers/adherence_provider.dart';
import '../providers/medication_provider.dart';
import '../providers/settings_provider.dart';
import '../services/ocr_service.dart';
import '../utils/translations.dart';
import 'medication_item.dart';
import 'medication_info_modal.dart';
import 'medication_form_modal.dart';

class _MedicationEntry {
  final int index;
  final Map<String, String?> item;

  const _MedicationEntry({required this.index, required this.item});
}

class MedicationList extends StatefulWidget {
  const MedicationList({super.key});

  @override
  State<MedicationList> createState() => _MedicationListState();
}

class _MedicationListState extends State<MedicationList> {
  String _selectedTypeFilter = 'all';
  String _selectedDoctorFilter = 'all';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _doctorKey(String name, String specialty) =>
      '${name.trim().toLowerCase()}|||${specialty.trim().toLowerCase()}';

  String _doctorDisplay(String name, String specialty) {
    final n = name.trim();
    final s = specialty.trim();
    if (n.isEmpty && s.isEmpty) return '';
    if (s.isEmpty) return n;
    if (n.isEmpty) return s;
    return '$n - $s';
  }

  bool _matchesTypeFilter(Map<String, String?> item) {
    if (_selectedTypeFilter == 'all') return true;

    final disease = (item['chronicDisease'] ?? '').trim();
    if (_selectedTypeFilter == 'bp') {
      return disease == 'ارتفاع ضغط الدم';
    }
    if (_selectedTypeFilter == 'bs') {
      return disease == 'السكري';
    }
    if (_selectedTypeFilter == 'general') {
      return disease.isEmpty ||
          (disease != 'ارتفاع ضغط الدم' && disease != 'السكري');
    }

    return true;
  }

  bool _matchesDoctorFilter(Map<String, String?> item) {
    if (_selectedDoctorFilter == 'all') return true;

    final doctorName = (item['doctorName'] ?? '').trim();
    final doctorSpecialty = (item['doctorSpecialty'] ?? '').trim();
    final key = _doctorKey(doctorName, doctorSpecialty);
    return key == _selectedDoctorFilter;
  }

  bool _matchesSearch(Map<String, String?> item) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return true;

    final name = (item['name'] ?? '').toLowerCase();
    final dose = (item['dose'] ?? '').toLowerCase();
    final doctorName = (item['doctorName'] ?? '').toLowerCase();
    final doctorSpecialty = (item['doctorSpecialty'] ?? '').toLowerCase();
    final chronicDisease = (item['chronicDisease'] ?? '').toLowerCase();

    return name.contains(query) ||
        dose.contains(query) ||
        doctorName.contains(query) ||
        doctorSpecialty.contains(query) ||
        chronicDisease.contains(query);
  }

  List<Map<String, String>> _buildDoctorOptions(List<Map<String, String?>> items) {
    final seen = <String>{};
    final doctors = <Map<String, String>>[];

    for (final item in items) {
      final doctorName = (item['doctorName'] ?? '').trim();
      final doctorSpecialty = (item['doctorSpecialty'] ?? '').trim();
      if (doctorName.isEmpty && doctorSpecialty.isEmpty) continue;

      final key = _doctorKey(doctorName, doctorSpecialty);
      if (seen.contains(key)) continue;
      seen.add(key);

      doctors.add({
        'key': key,
        'label': _doctorDisplay(doctorName, doctorSpecialty),
      });
    }

    doctors.sort((a, b) =>
        (a['label'] ?? '').toLowerCase().compareTo((b['label'] ?? '').toLowerCase()));
    return doctors;
  }

  List<_MedicationEntry> _buildFilteredEntries(List<Map<String, String?>> items) {
    final filtered = <_MedicationEntry>[];

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      if (!_matchesTypeFilter(item)) continue;
      if (!_matchesDoctorFilter(item)) continue;
      if (!_matchesSearch(item)) continue;

      filtered.add(_MedicationEntry(index: i, item: item));
    }

    return filtered;
  }

  Future<void> _showAddOptions(BuildContext context) async {
    final lang = Provider.of<SettingsProvider>(context, listen: false).language;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(AppTranslations.translate('add_medication_manually', lang)),
              onTap: () {
                Navigator.of(ctx).pop();
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (_) => MedicationFormModal(
                    initialIntervalHours: null,
                    onSave: (
                      name,
                      dose, {
                      imagePath,
                      intervalHours,
                      startTime,
                      startDate,
                      chronicDisease,
                      doctorName,
                      doctorSpecialty,
                      pillCount,
                      warningBarrier,
                    }) {
                      Provider.of<MedicationProvider>(context, listen: false)
                          .add(
                            name,
                            dose,
                            imagePath: imagePath,
                            intervalHours: intervalHours ?? 24,
                            startTime: startTime,
                            startDate: startDate,
                            chronicDisease: chronicDisease,
                            doctorName: doctorName,
                            doctorSpecialty: doctorSpecialty,
                            pillCount: pillCount,
                            warningBarrier: warningBarrier,
                          );
                    },
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: Text(AppTranslations.translate('add_medication_camera', lang)),
              onTap: () async {
                Navigator.of(ctx).pop();
                await _handleAddFromPhoto(context, fromCamera: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(AppTranslations.translate('add_medication_gallery', lang)),
              onTap: () async {
                Navigator.of(ctx).pop();
                await _handleAddFromPhoto(context, fromCamera: false);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAddFromPhoto(
    BuildContext context, {
    required bool fromCamera,
  }) async {
    final ocr = OcrService();
    final path = await ocr.pickImagePath(fromCamera: fromCamera);
    if (path == null) return;
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final result = await ocr.extractFromFile(path);

    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    if (result == null || !context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => MedicationFormModal(
        initialName: result.name,
        initialDose: result.dose,
        initialImagePath: result.imagePath,
        initialIntervalHours: null,
        onSave: (
          name,
          dose, {
          imagePath,
          intervalHours,
          startTime,
          startDate,
          chronicDisease,
          doctorName,
          doctorSpecialty,
          pillCount,
          warningBarrier,
        }) {
          Provider.of<MedicationProvider>(context, listen: false).add(
            name,
            dose,
            imagePath: imagePath,
            intervalHours: intervalHours ?? 24,
            startTime: startTime,
            startDate: startDate,
            chronicDisease: chronicDisease,
            doctorName: doctorName,
            doctorSpecialty: doctorSpecialty,
            pillCount: pillCount,
            warningBarrier: warningBarrier,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String lang) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.local_pharmacy_outlined, color: Color(0xFF57B6A8), size: 42),
        const SizedBox(height: 12),
        Text(
          AppTranslations.translate('no_medications', lang),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          AppTranslations.translate('add_medication', lang),
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  void _showInfo(BuildContext context, Map<String, String?> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => MedicationInfoModal(
        name: item['name'] ?? '',
        dose: item['dose'] ?? '',
        imagePath: item['imagePath'],
        intervalHours: int.tryParse(item['intervalHours'] ?? '') ?? 24,
        startTime: item['startTime'],
        startDate: item['startDate'],
        doctorName: item['doctorName'],
        doctorSpecialty: item['doctorSpecialty'],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, sp, child) {
        final lang = sp.language;
        final provider = Provider.of<MedicationProvider>(context);
        final items = provider.items;
        final dropdownBg = Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).cardColor
            : Colors.white;
        final dropdownTextColor = Theme.of(context).colorScheme.onSurface;
        final doctorOptions = _buildDoctorOptions(items);

        final selectedDoctorExists = _selectedDoctorFilter == 'all' ||
            doctorOptions.any((option) => option['key'] == _selectedDoctorFilter);
        if (!selectedDoctorExists) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {
              _selectedDoctorFilter = 'all';
            });
          });
        }

        final filteredEntries = _buildFilteredEntries(items);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppTranslations.translate('medications_list', lang),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  )
                ],
              ),
            ),
            Center(
              child: ElevatedButton.icon(
                onPressed: () => _showAddOptions(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF57B6A8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  elevation: 0,
                ),
                icon: const Icon(Icons.add, size: 18),
                label: Text(
                  AppTranslations.translate('add_medication', lang),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      key: ValueKey<String>('type_$_selectedTypeFilter'),
                      initialValue: _selectedTypeFilter,
                      dropdownColor: dropdownBg,
                      style: TextStyle(color: dropdownTextColor),
                      decoration: InputDecoration(
                        labelText: lang == 'ar' ? 'نوع الدواء' : 'Medication type',
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: [
                        DropdownMenuItem<String>(
                          value: 'all',
                          child: Text(lang == 'ar' ? 'الكل' : 'All'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'general',
                          child: Text(AppTranslations.translate('general_medication', lang)),
                        ),
                        DropdownMenuItem<String>(
                          value: 'bs',
                          child: Text(AppTranslations.translate('blood_sugar_medication', lang)),
                        ),
                        DropdownMenuItem<String>(
                          value: 'bp',
                          child: Text(AppTranslations.translate('blood_pressure_medication', lang)),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _selectedTypeFilter = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      key: ValueKey<String>('doctor_${_selectedDoctorFilter}_${doctorOptions.length}'),
                      initialValue: selectedDoctorExists ? _selectedDoctorFilter : 'all',
                      dropdownColor: dropdownBg,
                      style: TextStyle(color: dropdownTextColor),
                      decoration: InputDecoration(
                        labelText: lang == 'ar' ? 'الطبيب' : 'Doctor',
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: [
                        DropdownMenuItem<String>(
                          value: 'all',
                          child: Text(lang == 'ar' ? 'الكل' : 'All'),
                        ),
                        ...doctorOptions.map((doctor) {
                          return DropdownMenuItem<String>(
                            value: doctor['key']!,
                            child: Text(
                              doctor['label']!,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _selectedDoctorFilter = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.trim().isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        ),
                  hintText: lang == 'ar'
                      ? 'ابحث عن الدواء أو الجرعة أو الطبيب'
                      : 'Search medication, dose, or doctor',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: items.isEmpty
                  ? _buildEmptyState(context, lang)
                  : filteredEntries.isEmpty
                      ? Center(
                          child: Text(
                            lang == 'ar'
                                ? 'لا توجد أدوية تطابق الفلتر المحدد'
                                : 'No medications match the selected filters',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                        )
                      : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      itemCount: filteredEntries.length,
                      itemBuilder: (context, i) {
                        final entry = filteredEntries[i];
                        final item = entry.item;
                        final itemIndex = entry.index;
                        final notifPrefix = item['notifPrefix'] ?? '';
                        final missedCount = provider.getMissedDosesCount(notifPrefix);

                        return MedicationItem(
                          name: item['name'] ?? '',
                          dose: item['dose'] ?? '',
                          imagePath: item['imagePath'],
                          intervalHours: item['intervalHours'],
                          startTime: item['startTime'],
                          startDate: item['startDate'],
                          chronicDisease: item['chronicDisease'],
                          missedDosesCount: missedCount,
                          onTap: () => _showInfo(context, item),
                          onEdit: () {
                            Navigator.pop(context);
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              useSafeArea: true,
                              builder: (_) => MedicationFormModal(
                                initialName: item['name'],
                                initialDose: item['dose'],
                                initialImagePath: item['imagePath'],
                                initialIntervalHours: int.tryParse(item['intervalHours'] ?? '24') ?? 24,
                                initialStartTime: item['startTime'],
                                initialStartDate: item['startDate'],
                                initialChronicDisease: item['chronicDisease'],
                                initialDoctorName: item['doctorName'],
                                initialDoctorSpecialty: item['doctorSpecialty'],
                                initialPillCount: int.tryParse(item['pillCountRemaining'] ?? ''),
                                initialWarningBarrier: int.tryParse(item['warningBarrier'] ?? '5'),
                                onSave: (
                                  name,
                                  dose, {
                                  imagePath,
                                  intervalHours,
                                  startTime,
                                  startDate,
                                  chronicDisease,
                                  doctorName,
                                  doctorSpecialty,
                                  pillCount,
                                  warningBarrier,
                                }) {
                                  final oldName = item['name'] ?? '';
                                  final oldDose = item['dose'] ?? '';

                                  unawaited(() async {
                                    await context
                                        .read<AdherenceProvider>()
                                        .migrateMedicationIdentity(
                                          oldMedicationName: oldName,
                                          oldDose: oldDose,
                                          newMedicationName: name,
                                          newDose: dose,
                                        );

                                    await provider.updateAt(
                                      itemIndex,
                                      name,
                                      dose,
                                      imagePath: imagePath,
                                      intervalHours: intervalHours ?? 24,
                                      startTime: startTime,
                                      startDate: startDate,
                                      chronicDisease: chronicDisease,
                                      doctorName: doctorName,
                                      doctorSpecialty: doctorSpecialty,
                                      pillCount: pillCount,
                                      warningBarrier: warningBarrier,
                                    );
                                  }());
                                },
                              ),
                            );
                          },
                          onDelete: () {
                            Navigator.pop(context);
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text(AppTranslations.translate('delete_medication', lang)),
                                content: Text('${AppTranslations.translate('confirm_delete_medication', lang)} ${item['name']}؟'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: Text(AppTranslations.translate('cancel', lang)),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      provider.removeAt(itemIndex);
                                    },
                                    child: Text(
                                      AppTranslations.translate('delete', lang),
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          onToggleLastStatus: () async {
                            Navigator.pop(context);

                            final medicationName = item['name'] ?? '';
                            final medicationDose = item['dose'] ?? '';

                            final newStatus = await context
                                .read<AdherenceProvider>()
                                .toggleLatestMedicationStatus(
                                  medicationName: medicationName,
                                  dose: medicationDose,
                                );

                            if (!context.mounted) return;

                            final message = newStatus == null
                                ? (lang == 'ar'
                                    ? 'لا توجد جرعة مسجلة لهذا الدواء.'
                                    : 'No recorded dose found for this medication.')
                                : newStatus
                                    ? (lang == 'ar'
                                        ? 'تم تغيير آخر جرعة إلى: مأخوذة.'
                                        : 'Last dose status updated to: taken.')
                                    : (lang == 'ar'
                                        ? 'تم تغيير آخر جرعة إلى: غير مأخوذة.'
                                        : 'Last dose status updated to: not taken.');

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(message)),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
