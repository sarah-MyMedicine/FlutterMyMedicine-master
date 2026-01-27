import 'package:flutter/material.dart';

class BloodPressureFormModal extends StatefulWidget {
  final void Function(int systolic, int diastolic) onSave;
  const BloodPressureFormModal({super.key, required this.onSave});

  @override
  State<BloodPressureFormModal> createState() => _BloodPressureFormModalState();
}

class _BloodPressureFormModalState extends State<BloodPressureFormModal> {
  final _formKey = GlobalKey<FormState>();
  final _sysCtrl = TextEditingController();
  final _diaCtrl = TextEditingController();

  @override
  void dispose() {
    _sysCtrl.dispose();
    _diaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('إضافة قياس الضغط', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Form(
                key: _formKey,
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _sysCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'ضغط انقباضي'),
                        validator: (v) => (v == null || int.tryParse(v) == null) ? 'أدخل رقماً' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _diaCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'ضغط انبساطي'),
                        validator: (v) => (v == null || int.tryParse(v) == null) ? 'أدخل رقماً' : null,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      widget.onSave(int.parse(_sysCtrl.text.trim()), int.parse(_diaCtrl.text.trim()));
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('حفظ'))
            ],
          ),
        ),
      ),
    );
  }
}