import 'package:flutter/material.dart';

class SymptomLogPage extends StatefulWidget {
  const SymptomLogPage({super.key});

  @override
  State<SymptomLogPage> createState() => _SymptomLogPageState();
}

class _SymptomLogPageState extends State<SymptomLogPage> {
  final List<_SymptomEntry> _entries = [];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8F8),
        appBar: AppBar(
          backgroundColor: const Color(0xFF57B6A8),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'سجل الأعراض',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
          actions: const [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.shield_outlined, color: Colors.white),
            ),
            Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.location_on_outlined, color: Colors.white),
            ),
          ],
        ),
        body: Column(
          children: [
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                onPressed: _openNewEntryDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF57B6A8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  elevation: 0,
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('تسجيل عرض', style: TextStyle(fontSize: 14)),
              ),
            ),
            const SizedBox(height: 36),
            if (_entries.isEmpty) _buildEmptyState() else _buildList(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          SizedBox(height: 12),
          Icon(Icons.warning_amber_rounded, color: Color(0xFFBDBDBD), size: 30),
          SizedBox(height: 12),
          Text(
            'لا توجد أعراض مسجلة',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF525252)),
          ),
          SizedBox(height: 6),
          Text(
            "انقر على زر 'تسجيل عرض' لبدء المتابعة.",
            style: TextStyle(fontSize: 13, color: Color(0xFF7B7B7B)),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
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
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemCount: _entries.length,
      ),
    );
  }

  void _openNewEntryDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => _SymptomDialog(
        onSave: (entry) {
          setState(() => _entries.add(entry));
        },
      ),
    );
  }
}

class _SymptomDialog extends StatefulWidget {
  final void Function(_SymptomEntry entry) onSave;
  const _SymptomDialog({required this.onSave});

  @override
  State<_SymptomDialog> createState() => _SymptomDialogState();
}

class _SymptomDialogState extends State<_SymptomDialog> {
  final _symptomCtrl = TextEditingController();
  final _drugCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _severity = 'متوسط';
  final Map<String, bool> _riskFactors = {
    'مدخن': false,
    'لديه حساسية': false,
    'أمراض الكبد': false,
  };
  bool _shareWithOrg = false;
  bool _keepPrivate = true;

  @override
  void dispose() {
    _symptomCtrl.dispose();
    _drugCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              const Center(
                child: Text(
                  'تسجيل عرض جديد',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField('العرض', 'مثال: صداع، غثيان، ألم في المفاصل...', _symptomCtrl),
              const SizedBox(height: 12),
              _buildTextField('الدواء المحتمل المسبب (اختياري)', 'اختر من قائمة أدويتك --', _drugCtrl, hasDropdown: true),
              const SizedBox(height: 12),
              const Text('الحدة', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              _buildSeveritySelector(),
              const SizedBox(height: 12),
              const Text('حالات صحية / عوامل خطورة', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              _buildRiskFactors(),
              const SizedBox(height: 12),
              _buildMultilineField('ملاحظات إضافية', 'وصف إضافي للحالة...', _notesCtrl),
              const SizedBox(height: 12),
              const Text('خيارات المشاركة والخصوصية', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              _buildShareOptions(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('إلغاء'),
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
                            title: _symptomCtrl.text.isEmpty ? 'عرض بدون اسم' : _symptomCtrl.text,
                            notes: _notesCtrl.text,
                            severity: _severity,
                            dateLabel: 'اليوم',
                          ),
                        );
                        Navigator.pop(context);
                      },
                      child: const Text('حفظ'),
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

  Widget _buildTextField(String label, String hint, TextEditingController controller, {bool hasDropdown = false}) {
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
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                    color: Colors.grey.shade50,
                  ),
                  child: const Text('سهم', style: TextStyle(fontSize: 12, color: Colors.grey)),
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

  Widget _buildSeveritySelector() {
    final options = ['خفيف', 'متوسط', 'شديد'];
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

  Widget _buildShareOptions() {
    return Column(
      children: [
        SwitchListTile(
          value: _shareWithOrg,
          onChanged: (v) => setState(() => _shareWithOrg = v),
          title: const Text('إبلاغ الجهات الطبية'),
          subtitle: const Text('لزيادة فرص استخدام الدواء والمساهمة في رصد الآثار الجانبية.'),
          activeThumbColor: const Color(0xFF57B6A8),
          contentPadding: EdgeInsets.zero,
        ),
        RadioListTile<bool>(
          value: true,
          groupValue: _keepPrivate,
          onChanged: (_) => setState(() => _keepPrivate = true),
          title: const Text('أود حفظها لدي فقط'),
          subtitle: const Text('حفظ في سجلي الشخصي فقط دون مشاركة'),
          contentPadding: EdgeInsets.zero,
        ),
        RadioListTile<bool>(
          value: false,
          groupValue: _keepPrivate,
          onChanged: (_) => setState(() => _keepPrivate = false),
          title: const Text('موافق على مشاركتها'),
          subtitle: const Text('السماح بمشاركة العرض مع الجهات الطبية عند الحاجة'),
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
