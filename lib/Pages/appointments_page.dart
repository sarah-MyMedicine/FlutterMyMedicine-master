import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/appointment_provider.dart';
import '../services/notification_service.dart';

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  @override
  void initState() {
    super.initState();
    final ap = Provider.of<AppointmentProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ap.load();
    });
  }

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
            'مواعيدي الطبية',
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
                onPressed: () => _openNewAppointmentDialog(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF57B6A8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  elevation: 0,
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('موعد جديد', style: TextStyle(fontSize: 14)),
              ),
            ),
            const SizedBox(height: 36),
            Consumer<AppointmentProvider>(
              builder: (context, ap, _) {
                return ap.appointments.isEmpty ? _buildEmptyState() : _buildList(ap);
              },
            ),
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
          Icon(Icons.calendar_month, color: Color(0xFF57B6A8), size: 50),
          SizedBox(height: 12),
          Text(
            'لا توجد مواعيد',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF525252)),
          ),
          SizedBox(height: 6),
          Text(
            'اضف مواعيدك الطبية ولا تتأخر أبداً',
            style: TextStyle(fontSize: 13, color: Color(0xFF7B7B7B)),
          ),
        ],
      ),
    );
  }

  Widget _buildList(AppointmentProvider ap) {
    return Expanded(
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final appt = ap.appointments[index];
          final dateStr = '${appt.appointmentDateTime.day}/${appt.appointmentDateTime.month}/${appt.appointmentDateTime.year}';
          final timeStr = '${appt.appointmentDateTime.hour.toString().padLeft(2, '0')}:${appt.appointmentDateTime.minute.toString().padLeft(2, '0')}';

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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appt.doctorName,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            appt.specialty,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      onPressed: () => ap.delete(appt.id),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: Color(0xFF57B6A8)),
                    const SizedBox(width: 4),
                    Text(dateStr, style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 16),
                    const Icon(Icons.access_time, size: 14, color: Color(0xFF57B6A8)),
                    const SizedBox(width: 4),
                    Text(timeStr, style: const TextStyle(fontSize: 12)),
                  ],
                ),
                if (appt.notes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    appt.notes,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemCount: ap.appointments.length,
      ),
    );
  }

  void _openNewAppointmentDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => _AppointmentDialog(
        onSave: (doctorName, specialty, appointmentDateTime, notes) async {
          final ap = Provider.of<AppointmentProvider>(context, listen: false);
          await ap.add(doctorName, specialty, appointmentDateTime, notes);

          // Schedule notification for 1 day before
          final oneDayBefore = appointmentDateTime.subtract(const Duration(days: 1));
          final notificationService = NotificationService();
          await notificationService.scheduleOneOff(
            prefix: 'appointment',
            title: 'تنبيه الموعد الطبي',
            body: 'لديك موعد غداً مع د. $doctorName ($specialty)',
            when: oneDayBefore,
          );

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حفظ الموعد')),
          );
        },
      ),
    );
  }
}

class _AppointmentDialog extends StatefulWidget {
  final void Function(String doctorName, String specialty, DateTime appointmentDateTime, String notes) onSave;
  const _AppointmentDialog({required this.onSave});

  @override
  State<_AppointmentDialog> createState() => _AppointmentDialogState();
}

class _AppointmentDialogState extends State<_AppointmentDialog> {
  final _doctorCtrl = TextEditingController();
  final _specialtyCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _selectedTime = TimeOfDay.now();
  }

  @override
  void dispose() {
    _doctorCtrl.dispose();
    _specialtyCtrl.dispose();
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
                  'إضافة موعد جديد',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField('اسم الطبيب', 'د. محمد', _doctorCtrl, icon: Icons.person),
              const SizedBox(height: 12),
              _buildTextField('التخصص', 'مثال: باطنية، أسنان', _specialtyCtrl),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildDateField(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTimeField(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildMultilineField('أسئلة / ملاحظات', 'اكتب ها الأسئلة التي تود طرحها على الطبيب', _notesCtrl),
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
                        final appointmentDateTime = DateTime(
                          _selectedDate.year,
                          _selectedDate.month,
                          _selectedDate.day,
                          _selectedTime.hour,
                          _selectedTime.minute,
                        );
                        widget.onSave(
                          _doctorCtrl.text.isEmpty ? 'طبيب' : _doctorCtrl.text,
                          _specialtyCtrl.text.isEmpty ? 'تخصص' : _specialtyCtrl.text,
                          appointmentDateTime,
                          _notesCtrl.text,
                        );
                        Navigator.pop(context);
                      },
                      child: const Text('حفظ الموعد'),
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

  Widget _buildTextField(String label, String hint, TextEditingController controller, {IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.grey[100],
            prefixIcon: icon != null ? Icon(icon, size: 20) : null,
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

  Widget _buildMultilineField(String label, String hint, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
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

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('التاريخ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null) {
              setState(() => _selectedDate = picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}',
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('الوقت', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: _selectedTime,
            );
            if (picked != null) {
              setState(() => _selectedTime = picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}'.replaceFirst(':', ' : '),
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }
}
