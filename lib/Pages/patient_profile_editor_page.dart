import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import '../services/patient_data_sync_service.dart';
import '../utils/translations.dart';

class PatientProfileEditorPage extends StatefulWidget {
  final String? patientUsername;
  final String? patientDisplayName;

  const PatientProfileEditorPage({
    super.key,
    this.patientUsername,
    this.patientDisplayName,
  });

  @override
  State<PatientProfileEditorPage> createState() => _PatientProfileEditorPageState();
}

class _PatientProfileEditorPageState extends State<PatientProfileEditorPage> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  PatientGender? _gender;
  List<String> _chronicDiseases = <String>[];
  bool _isLoading = true;
  bool _isSaving = false;

  static const List<_DiseaseOption> _diseaseOptions = [
    _DiseaseOption('ارتفاع ضغط الدم', 'chronic_disease_hypertension'),
    _DiseaseOption('السكري', 'chronic_disease_diabetes'),
    _DiseaseOption('ارتفاع الكوليستيرول / الدهون الثلاثية', 'chronic_disease_cholesterol'),
    _DiseaseOption('قصور القلب', 'chronic_disease_heart_failure'),
    _DiseaseOption('أمراض الكلى', 'chronic_disease_kidney'),
    _DiseaseOption('أمراض الكبد', 'chronic_disease_liver'),
    _DiseaseOption('الصرع', 'chronic_disease_epilepsy'),
    _DiseaseOption('الباركنسون', 'chronic_disease_parkinsons'),
    _DiseaseOption('السرطان', 'chronic_disease_cancer'),
    _DiseaseOption('لا توجد أمراض مزمنة', 'chronic_disease_none'),
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final targetUsername = widget.patientUsername?.trim().toLowerCase();

    try {
      if (targetUsername == null || targetUsername.isEmpty || targetUsername == userProvider.username?.toLowerCase()) {
        _nameController.text = settings.name;
        _ageController.text = settings.age?.toString() ?? '';
        _gender = settings.gender;
        _chronicDiseases = List<String>.from(settings.chronicDiseases);
      } else {
        final snapshot = await ApiService().getPatientDataSnapshot(patientUsername: targetUsername);
        _nameController.text = (snapshot['settings_name'] ?? widget.patientDisplayName ?? '').toString();
        _ageController.text = snapshot['settings_age']?.toString() ?? '';
        final genderValue = snapshot['settings_gender']?.toString();
        _gender = genderValue == 'male'
            ? PatientGender.male
            : genderValue == 'female'
                ? PatientGender.female
                : null;
        final diseases = snapshot['settings_chronic_diseases'];
        if (diseases is List) {
          _chronicDiseases = diseases.map((item) => item.toString()).toList();
        }
      }
    } catch (e) {
      debugPrint('Failed to load profile data: $e');
      _nameController.text = widget.patientDisplayName ?? '';
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _saveProfile() async {
    final lang = Provider.of<SettingsProvider>(context, listen: false).language;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final targetUsername = widget.patientUsername?.trim().toLowerCase() ?? userProvider.username?.toLowerCase();

    final name = _nameController.text.trim();
    final age = int.tryParse(_ageController.text.trim());

    if (name.isEmpty || age == null || age <= 0 || _gender == null || targetUsername == null || targetUsername.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lang == 'ar'
                ? 'الاسم والعمر والجنس مطلوبون'
                : 'Name, age, and gender are required',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final snapshot = <String, dynamic>{
      'settings_name': name,
      'settings_age': age,
      'settings_gender': _gender == PatientGender.male ? 'male' : 'female',
      'settings_chronic_diseases': _chronicDiseases,
    };

    try {
      await ApiService().savePatientDataSnapshot(
        snapshot,
        patientUsername: targetUsername,
      );
      if (!mounted) return;
      await PatientDataSyncService().syncAfterAuthentication(
        context: context,
        username: targetUsername,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lang == 'ar' ? 'تم تحديث الملف بنجاح' : 'Profile updated successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lang == 'ar' ? 'فشل تحديث الملف' : 'Failed to update profile',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<SettingsProvider>(context).language;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = widget.patientDisplayName?.trim().isNotEmpty == true
        ? widget.patientDisplayName!.trim()
        : (lang == 'ar' ? 'الملف الشخصي للمريض' : 'Patient Profile');

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(
              label: lang == 'ar' ? 'الاسم' : 'Name',
              controller: _nameController,
              hint: lang == 'ar' ? 'أدخل الاسم' : 'Enter name',
            ),
            const SizedBox(height: 12),
            _buildTextField(
              label: lang == 'ar' ? 'العمر' : 'Age',
              controller: _ageController,
              hint: lang == 'ar' ? 'أدخل العمر' : 'Enter age',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            Text(
              lang == 'ar' ? 'الجنس' : 'Gender',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<PatientGender>(
              initialValue: _gender,
              items: [
                DropdownMenuItem(
                  value: PatientGender.male,
                  child: Text(lang == 'ar' ? 'ذكر' : 'Male'),
                ),
                DropdownMenuItem(
                  value: PatientGender.female,
                  child: Text(lang == 'ar' ? 'أنثى' : 'Female'),
                ),
              ],
              onChanged: (value) => setState(() => _gender = value),
              decoration: InputDecoration(
                filled: true,
                fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              lang == 'ar' ? 'الأمراض المزمنة' : 'Chronic Diseases',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ..._diseaseOptions.map((option) {
              return CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _chronicDiseases.contains(option.storageValue),
                onChanged: (_) {
                  setState(() {
                    if (_chronicDiseases.contains(option.storageValue)) {
                      _chronicDiseases.remove(option.storageValue);
                    } else {
                      if (option.storageValue == 'لا توجد أمراض مزمنة') {
                        _chronicDiseases.clear();
                      } else {
                        _chronicDiseases.remove('لا توجد أمراض مزمنة');
                      }
                      _chronicDiseases.add(option.storageValue);
                    }
                  });
                },
                title: Text(AppTranslations.translate(option.translationKey, lang)),
                controlAffinity: ListTileControlAffinity.leading,
              );
            }),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                child: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(lang == 'ar' ? 'حفظ' : 'Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }
}

class _DiseaseOption {
  final String storageValue;
  final String translationKey;

  const _DiseaseOption(this.storageValue, this.translationKey);
}
