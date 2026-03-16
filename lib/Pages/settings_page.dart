import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/user_provider.dart';
import '../utils/translations.dart';
import 'profile_page.dart';
import 'reminder_reliability_check_page.dart';
import 'login_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _provinceCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final sp = Provider.of<SettingsProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await sp.load();
      _nameCtrl.text = sp.name;
      _ageCtrl.text = sp.age?.toString() ?? '';
      _countryCtrl.text = sp.country ?? '';
      _provinceCtrl.text = sp.province ?? '';
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _countryCtrl.dispose();
    _provinceCtrl.dispose();
    super.dispose();
  }

  Future<void> _logout(String lang) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppTranslations.translate('logout_confirm_title', lang)),
        content: Text(AppTranslations.translate('logout_confirm_message', lang)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppTranslations.translate('cancel', lang)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(AppTranslations.translate('logout', lang)),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;

    await Provider.of<UserProvider>(context, listen: false).logout(context: context);

    if (!mounted) return;

    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, sp, _) {
        final lang = sp.language;
        return Directionality(
          textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: Colors.grey[50],
            appBar: AppBar(
              title: Text(AppTranslations.translate('settings', lang)),
              centerTitle: true,
              backgroundColor: Colors.white,
              elevation: 1,
            ),
            body: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Account & Profile Section
                      Consumer<UserProvider>(
                        builder: (context, userProvider, _) {
                          return _buildSection(
                            lang: lang,
                            title: AppTranslations.translate('profile', lang),
                            icon: Icons.account_circle,
                            iconColor: Colors.blue,
                            children: [
                              if (userProvider.username != null)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppTranslations.translate('username', lang),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      userProvider.username ?? 'N/A',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          if (userProvider.password != null) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => ProfilePage(
                                                  password: userProvider.password!,
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                        icon: const Icon(Icons.security, size: 18),
                                        label: Text(
                                          AppTranslations.translate('account_security', lang),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue.shade700,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        onPressed: () => _logout(lang),
                                        icon: const Icon(Icons.logout, size: 18),
                                        label: Text(
                                          AppTranslations.translate('logout', lang),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red,
                                          side: const BorderSide(color: Colors.red),
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Personal Profile Section
                      _buildSection(
                        lang: lang,
                        title: AppTranslations.translate('personal_profile', lang),
                        children: [
                          _buildTextField(
                            label: AppTranslations.translate('name', lang),
                            controller: _nameCtrl,
                            hint: AppTranslations.translate('visitor', lang),
                            onChanged: (v) => sp.setName(v),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  label: AppTranslations.translate('age', lang),
                                  controller: _ageCtrl,
                                  hint: '',
                                  keyboardType: TextInputType.number,
                                  onChanged: (v) {
                                    final n = int.tryParse(v);
                                    sp.setAge(n);
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppTranslations.translate('gender', lang),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    DropdownButtonFormField<PatientGender>(
                                      initialValue: sp.gender,
                                      items: [
                                        DropdownMenuItem(
                                          value: PatientGender.male,
                                          child: Text(AppTranslations.translate('male', lang)),
                                        ),
                                        DropdownMenuItem(
                                          value: PatientGender.female,
                                          child: Text(AppTranslations.translate('female', lang)),
                                        ),
                                      ],
                                      onChanged: (v) => sp.setGender(v),
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: Colors.grey[100],
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide.none,
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                      dropdownColor: Colors.white,
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  label: AppTranslations.translate('country', lang),
                                  controller: _countryCtrl,
                                  hint: '',
                                  onChanged: (v) => sp.setCountry(v),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTextField(
                                  label: AppTranslations.translate('province', lang),
                                  controller: _provinceCtrl,
                                  hint: '',
                                  onChanged: (v) => sp.setProvince(v),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            AppTranslations.translate('app_theme', lang),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildColorPicker(sp),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Chronic Diseases Section
                      _buildSection(
                        lang: lang,
                        title: AppTranslations.translate('chronic_diseases', lang),
                        icon: Icons.favorite,
                        iconColor: Colors.red,
                        children: [
                          Text(
                            AppTranslations.translate('chronic_diseases_desc', lang),
                            style: const TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                          const SizedBox(height: 12),
                          ..._buildChronicDiseaseCheckboxes(sp, lang),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Notification Settings Section
                      _buildSection(
                        lang: lang,
                        title: AppTranslations.translate('notification_settings', lang),
                        children: [
                          Text(
                            AppTranslations.translate('vibration_pattern', lang),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: sp.vibrationPattern,
                            items: [
                              DropdownMenuItem(
                                value: 'default',
                                child: Text(AppTranslations.translate('default', lang)),
                              ),
                              DropdownMenuItem(
                                value: 'short',
                                child: Text(AppTranslations.translate('short', lang)),
                              ),
                              DropdownMenuItem(
                                value: 'long',
                                child: Text(AppTranslations.translate('long', lang)),
                              ),
                            ],
                            onChanged: (v) {
                              if (v != null) sp.setVibrationPattern(v);
                            },
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.grey[100],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            dropdownColor: Colors.white,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // Test vibration functionality
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('اختبار الاهتزاز'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.vibration, size: 20),
                              label: Text(AppTranslations.translate('test_vibration', lang)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ReminderReliabilityCheckPage(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.verified_user_outlined, size: 20),
                              label: Text(
                                AppTranslations.translate('reminder_reliability_check', lang),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Language Settings Section
                      _buildSection(
                        lang: lang,
                        title: AppTranslations.translate('language', lang),
                        icon: Icons.language,
                        iconColor: const Color(0xFF57B6A8),
                        children: [
                          Text(
                            AppTranslations.translate('choose_app_language', lang),
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: sp.language,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.grey[100],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 'ar',
                                child: Text(lang == 'ar' ? 'العربية 🇸🇦' : 'Arabic 🇸🇦'),
                              ),
                              DropdownMenuItem(
                                value: 'en',
                                child: Text('English 🇬🇧'),
                              ),
                            ],
                            dropdownColor: Colors.white,
                            style: const TextStyle(color: Colors.black, fontSize: 14),
                            onChanged: (value) async {
                              if (value != null) {
                                await sp.setLanguage(value);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        AppTranslations.translate(
                                          value == 'ar' ? 'language_changed_ar' : 'language_changed_en',
                                          value,
                                        ),
                                      ),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 20,
                                  color: Colors.blue.shade700,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    AppTranslations.translate('translation_note', lang),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Health Reports Section
                      _buildSection(
                        lang: lang,
                        title: AppTranslations.translate('health_report', lang),
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // Create health report functionality
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('جاري إنشاء التقرير الصحي...'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.description_outlined, size: 20),
                              label: Text(AppTranslations.translate('generate_report', lang)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
                // Bottom Action Buttons
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Colors.grey),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            AppTranslations.translate('cancel', lang),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            // Save settings and close
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تم حفظ الإعدادات'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                            Future.delayed(
                              const Duration(milliseconds: 500),
                              () => Navigator.pop(context),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            AppTranslations.translate('save', lang),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSection({
    String? lang,
    required String title,
    IconData? icon,
    Color? iconColor,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: iconColor ?? Colors.black, size: 24),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildColorPicker(SettingsProvider sp) {
    final colors = [
      Colors.amber,
      Colors.deepPurple,
      Colors.pink,
      Colors.green,
      Colors.blue,
      Colors.teal,
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: colors.map((color) {
        final isSelected = sp.themeColor.value == color.value;
        return GestureDetector(
          onTap: () => sp.setThemeColor(color),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: Colors.black, width: 3)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white)
                : null,
          ),
        );
      }).toList(),
    );
  }

  List<Widget> _buildChronicDiseaseCheckboxes(SettingsProvider sp, String lang) {
    // Map of Arabic disease names (for storage) to translation keys
    final diseaseMap = {
      'ارتفاع ضغط الدم': 'chronic_disease_hypertension',
      'السكري': 'chronic_disease_diabetes',
      'ارتفاع الكوليستيرول / الدهون الثلاثية': 'chronic_disease_cholesterol',
      'قصور القلب': 'chronic_disease_heart_failure',
      'أمراض الكلى': 'chronic_disease_kidney',
      'أمراض الكبد': 'chronic_disease_liver',
      'الصرع': 'chronic_disease_epilepsy',
      'الباركنسون': 'chronic_disease_parkinsons',
      'السرطان': 'chronic_disease_cancer',
      'لا توجد أمراض مزمنة': 'chronic_disease_none',
    };

    return diseaseMap.entries.map((entry) {
      final diseaseKey = entry.key; // Arabic name for storage
      final translationKey = entry.value; // Translation key
      
      return CheckboxListTile(
        value: sp.chronicDiseases.contains(diseaseKey),
        onChanged: (v) => sp.toggleChronicDisease(diseaseKey),
        title: Text(
          AppTranslations.translate(translationKey, lang),
          style: const TextStyle(fontSize: 14),
        ),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
        dense: true,
        activeColor: Colors.teal,
      );
    }).toList();
  }
}
