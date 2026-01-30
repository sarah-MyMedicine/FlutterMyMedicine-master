import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('الاعدادات'),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 1,
        ),
        body: Consumer<SettingsProvider>(
          builder: (context, sp, _) {
            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Personal Profile Section
                      _buildSection(
                        title: 'الملف الشخصي',
                        children: [
                          _buildTextField(
                            label: 'الاسم',
                            controller: _nameCtrl,
                            hint: 'زائر',
                            onChanged: (v) => sp.setName(v),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  label: 'العمر',
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
                                    const Text(
                                      'الجنس',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    DropdownButtonFormField<PatientGender>(
                                      initialValue: sp.gender,
                                      items: const [
                                        DropdownMenuItem(
                                          value: PatientGender.male,
                                          child: Text('ذكر'),
                                        ),
                                        DropdownMenuItem(
                                          value: PatientGender.female,
                                          child: Text('أنثى'),
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
                                  label: 'البلد',
                                  controller: _countryCtrl,
                                  hint: '',
                                  onChanged: (v) => sp.setCountry(v),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTextField(
                                  label: 'المحافظة',
                                  controller: _provinceCtrl,
                                  hint: '',
                                  onChanged: (v) => sp.setProvince(v),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'لون التطبيق (التيمة)',
                            style: TextStyle(
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
                        title: 'الأمراض المزمنة',
                        icon: Icons.favorite,
                        iconColor: Colors.red,
                        children: [
                          const Text(
                            'في حال كان المريض يعاني من أي من الأمراض المزمنة التالية، يرجى تحديدها:',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                          const SizedBox(height: 12),
                          ..._buildChronicDiseaseCheckboxes(sp),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Drug Knowledge Section
                      _buildSection(
                        title: 'المعارف الدوائية',
                        icon: Icons.info_outline,
                        iconColor: Colors.blue,
                        children: [
                          const Text(
                            'هذه الخاصية تعرض معلومات مفصلة عن الأدوية المضافة، بما في ذلك التحذيرات والتفاعلات الدوائية.',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'تفعيل المعارف الدوائية',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                              Switch(
                                value: sp.drugKnowledgeEnabled,
                                onChanged: (v) => sp.setDrugKnowledge(v),
                                activeThumbColor: Colors.teal,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Notification Settings Section
                      _buildSection(
                        title: 'إعدادات الإشعارات',
                        children: [
                          const Text(
                            'نمط الاهتزاز',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: sp.vibrationPattern,
                            items: const [
                              DropdownMenuItem(
                                value: 'default',
                                child: Text('الافتراضي'),
                              ),
                              DropdownMenuItem(
                                value: 'short',
                                child: Text('قصير'),
                              ),
                              DropdownMenuItem(
                                value: 'long',
                                child: Text('طويل'),
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
                              label: const Text('اختبار الاهتزاز'),
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
                      const SizedBox(height: 16),

                      // Health Reports Section
                      _buildSection(
                        title: 'التقارير الصحية',
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
                              label: const Text('إنشاء تقرير صحي'),
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
                          child: const Text(
                            'إلغاء',
                            style: TextStyle(
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
                          child: const Text(
                            'حفظ والإغلاق',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSection({
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

  List<Widget> _buildChronicDiseaseCheckboxes(SettingsProvider sp) {
    final diseases = [
      'ارتفاع ضغط الدم',
      'السكري',
      'ارتفاع الكوليستيرول / الدهون الثلاثية',
      'قصور القلب',
      'أمراض الكلى',
      'أمراض الكبد',
      'الصرع',
      'الباركنسون',
      'السرطان',
    ];

    return diseases.map((disease) {
      return CheckboxListTile(
        value: sp.chronicDiseases.contains(disease),
        onChanged: (v) => sp.toggleChronicDisease(disease),
        title: Text(
          disease,
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
