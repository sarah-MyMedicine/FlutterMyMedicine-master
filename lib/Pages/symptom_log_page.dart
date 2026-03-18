import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../utils/translations.dart';

class SymptomLogPage extends StatefulWidget {
  const SymptomLogPage({super.key});

  @override
  State<SymptomLogPage> createState() => _SymptomLogPageState();
}

class _SymptomLogPageState extends State<SymptomLogPage> {
  final List<_SymptomEntry> _entries = [];

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, sp, child) {
        final lang = sp.language;
        
        return Directionality(
          textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: const Color(0xFFF6F8F8),
            appBar: AppBar(
              backgroundColor: const Color(0xFF57B6A8),
              elevation: 0,
              leading: IconButton(
                icon: Icon(lang == 'ar' ? Icons.arrow_back : Icons.arrow_forward, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                AppTranslations.translate('symptom_log_title', lang),
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
              ),
              centerTitle: true,
            ),
            body: Column(
              children: [
                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () => _openNewEntryDialog(lang),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF57B6A8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(
                      AppTranslations.translate('record_symptom', lang),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                if (_entries.isEmpty) _buildEmptyState(lang) else _buildList(lang),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String lang) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 12),
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFBDBDBD), size: 30),
          const SizedBox(height: 12),
          Text(
            AppTranslations.translate('no_symptoms_recorded', lang),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF525252)),
          ),
          const SizedBox(height: 6),
          Text(
            AppTranslations.translate('click_to_start_tracking', lang),
            style: const TextStyle(fontSize: 13, color: Color(0xFF7B7B7B)),
          ),
        ],
      ),
    );
  }

  Widget _buildList(String lang) {
    return Expanded(
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final e = _entries[index];
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF57B6A8).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        e.severity,
                        style: const TextStyle(color: Color(0xFF57B6A8), fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      e.dateLabel,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  e.title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                if (e.notes.isNotEmpty)
                  Text(
                    e.notes,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
              ],
            ),
          );
        },
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemCount: _entries.length,
      ),
    );
  }

  void _openNewEntryDialog(String lang) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => _SymptomDialog(
        lang: lang,
        onSave: (entry) {
          setState(() => _entries.add(entry));
        },
      ),
    );
  }
}

class _SymptomDialog extends StatefulWidget {
  final String lang;
  final void Function(_SymptomEntry entry) onSave;
  const _SymptomDialog({required this.lang, required this.onSave});

  @override
  State<_SymptomDialog> createState() => _SymptomDialogState();
}

class _SymptomDialogState extends State<_SymptomDialog> {
  final _symptomCtrl = TextEditingController();
  final _drugCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  late String _severity;
  late Map<String, bool> _riskFactors;
  bool _shareWithOrg = false;
  bool _keepPrivate = true;
  
  @override
  void initState() {
    super.initState();
    _severity = AppTranslations.translate('moderate', widget.lang);
    _riskFactors = {
      AppTranslations.translate('smoker', widget.lang): false,
      AppTranslations.translate('has_allergies', widget.lang): false,
      AppTranslations.translate('liver_disease', widget.lang): false,
    };
  }

  @override
  void dispose() {
    _symptomCtrl.dispose();
    _drugCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  AppTranslations.translate('record_new_symptom', lang),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                AppTranslations.translate('symptom', lang),
                AppTranslations.translate('symptom_example', lang),
                _symptomCtrl,
                lang,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                AppTranslations.translate('potential_drug_cause', lang),
                AppTranslations.translate('choose_from_medications', lang),
                _drugCtrl,
                lang,
                hasDropdown: true,
              ),
              const SizedBox(height: 12),
              Text(
                AppTranslations.translate('severity', lang),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              _buildSeveritySelector(lang),
              const SizedBox(height: 12),
              Text(
                AppTranslations.translate('health_conditions_risk', lang),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              _buildRiskFactors(),
              const SizedBox(height: 12),
              _buildMultilineField(
                AppTranslations.translate('additional_notes', lang),
                AppTranslations.translate('additional_description', lang),
                _notesCtrl,
              ),
              const SizedBox(height: 12),
              Text(
                AppTranslations.translate('sharing_privacy_options', lang),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              _buildShareOptions(lang),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(AppTranslations.translate('cancel', lang)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF57B6A8),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        widget.onSave(
                          _SymptomEntry(
                            title: _symptomCtrl.text.isEmpty 
                              ? AppTranslations.translate('symptom_without_name', lang)
                              : _symptomCtrl.text,
                            notes: _notesCtrl.text,
                            severity: _severity,
                            dateLabel: AppTranslations.translate('today', lang),
                          ),
                        );
                        Navigator.pop(context);
                      },
                      child: Text(AppTranslations.translate('save', lang)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller, String lang, {bool hasDropdown = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Stack(
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hint,
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            if (hasDropdown)
              Positioned(
                right: lang == 'ar' ? null : 8,
                left: lang == 'ar' ? 8 : null,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                    color: Colors.grey.shade50,
                  ),
                  child: Text(
                    AppTranslations.translate('arrow', lang),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildMultilineField(String label, String hint, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.grey[100],
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSeveritySelector(String lang) {
    final options = [
      AppTranslations.translate('mild', lang),
      AppTranslations.translate('moderate', lang),
      AppTranslations.translate('severe', lang),
    ];
    return Row(
      children: options.map((opt) {
        final selected = _severity == opt;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () => setState(() => _severity = opt),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFF57B6A8) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF57B6A8)),
                ),
                child: Center(
                  child: Text(
                    opt,
                    style: TextStyle(
                      color: selected ? Colors.white : const Color(0xFF57B6A8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRiskFactors() {
    return Column(
      children: _riskFactors.entries.map((e) {
        return CheckboxListTile(
          value: e.value,
          onChanged: (v) => setState(() => _riskFactors[e.key] = v ?? false),
          title: Text(e.key),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          activeColor: const Color(0xFF57B6A8),
        );
      }).toList(),
    );
  }

  Widget _buildShareOptions(String lang) {
    return Column(
      children: [
        SwitchListTile(
          value: _shareWithOrg,
          onChanged: (v) => setState(() => _shareWithOrg = v),
          title: Text(AppTranslations.translate('notify_medical_authorities', lang)),
          subtitle: Text(AppTranslations.translate('notify_medical_desc', lang)),
          activeThumbColor: const Color(0xFF57B6A8),
          contentPadding: EdgeInsets.zero,
        ),
        RadioListTile<bool>(
          value: true,
          groupValue: _keepPrivate,
          onChanged: (_) => setState(() => _keepPrivate = true),
          title: Text(AppTranslations.translate('keep_personal_only', lang)),
          subtitle: Text(AppTranslations.translate('save_personal_desc', lang)),
          contentPadding: EdgeInsets.zero,
        ),
        RadioListTile<bool>(
          value: false,
          groupValue: _keepPrivate,
          onChanged: (_) => setState(() => _keepPrivate = false),
          title: Text(AppTranslations.translate('agree_to_share', lang)),
          subtitle: Text(AppTranslations.translate('agree_share_desc', lang)),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }
}

class _SymptomEntry {
  final String title;
  final String notes;
  final String severity;
  final String dateLabel;

  _SymptomEntry({
    required this.title,
    required this.notes,
    required this.severity,
    required this.dateLabel,
  });
}
