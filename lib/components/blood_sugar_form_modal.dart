import 'package:flutter/material.dart';

class BloodSugarFormModal extends StatefulWidget {
  final void Function(int value) onSave;
  final int? initialValue;
  const BloodSugarFormModal({super.key, required this.onSave, this.initialValue});

  @override
  State<BloodSugarFormModal> createState() => _BloodSugarFormModalState();
}

class _BloodSugarFormModalState extends State<BloodSugarFormModal> {
  final _formKey = GlobalKey<FormState>();
  final _valCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      _valCtrl.text = widget.initialValue.toString();
    }
  }

  @override
  void dispose() {
    _valCtrl.dispose();
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
              Text(widget.initialValue != null ? 'تعديل قياس السكر' : 'إضافة قياس السكر', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Form(
                key: _formKey,
                child: TextFormField(
                  controller: _valCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'mg/dL'),
                  validator: (v) => (v == null || int.tryParse(v) == null) ? 'أدخل رقماً' : null,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      widget.onSave(int.parse(_valCtrl.text.trim()));
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