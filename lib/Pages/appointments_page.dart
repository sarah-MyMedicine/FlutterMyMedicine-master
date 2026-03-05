import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/appointment_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/translations.dart';
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
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final lang = settings.language;
        return Directionality(
          textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: const Color(0xFFF6F8F8),
            appBar: AppBar(
              backgroundColor: const Color(0xFF57B6A8),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                AppTranslations.translate('appointments', lang),
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
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
                    onPressed: () => _openNewAppointmentDialog(lang),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF57B6A8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(AppTranslations.translate('add_appointment', lang), style: const TextStyle(fontSize: 14)),
                  ),
                ),
                const SizedBox(height: 36),
                Consumer<AppointmentProvider>(
                  builder: (context, ap, _) {
                    return ap.appointments.isEmpty ? _buildEmptyState(lang) : _buildList(ap, lang);
                  },
                ),
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
          const Icon(Icons.calendar_month, color: Color(0xFF57B6A8), size: 50),
          const SizedBox(height: 12),
          Text(
            AppTranslations.translate('no_appointments', lang),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF525252)),
          ),
          const SizedBox(height: 6),
          Text(
            AppTranslations.translate('add', lang) + ' ' + AppTranslations.translate('appointments', lang),
            style: const TextStyle(fontSize: 13, color: Color(0xFF7B7B7B)),
          ),
        ],
      ),
    );
  }

  Widget _buildList(AppointmentProvider ap, String lang) {
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
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: Color(0xFF57B6A8), size: 20),
                          onPressed: () => _openEditAppointmentDialog(appt),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          onPressed: () => ap.delete(appt.id),
                        ),
                      ],
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

  void _openNewAppointmentDialog(String lang) {
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
          final sp = Provider.of<SettingsProvider>(context, listen: false);
          final lang = sp.language;
          await notificationService.scheduleOneOff(
            prefix: 'appointment',
            title: AppTranslations.translate('appointment_reminder', lang),
            body: lang == 'ar' ? 'لديك موعد غداً مع د. $doctorName ($specialty)' : 'You have an appointment tomorrow with Dr. $doctorName ($specialty)',
            when: oneDayBefore,
          );

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppTranslations.translate('appointment_saved', lang))),
          );
        },
      ),
    );
  }

  void _openEditAppointmentDialog(Appointment appt) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => _AppointmentDialog(
        appointment: appt,
        onSave: (doctorName, specialty, appointmentDateTime, notes) async {
          final ap = Provider.of<AppointmentProvider>(context, listen: false);
          await ap.update(appt.id, doctorName, specialty, appointmentDateTime, notes);

          final sp = Provider.of<SettingsProvider>(context, listen: false);
          final lang = sp.language;

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppTranslations.translate('appointment_updated', lang))),
          );
        },
      ),
    );
  }
}

class _AppointmentDialog extends StatefulWidget {
  final void Function(String doctorName, String specialty, DateTime appointmentDateTime, String notes) onSave;
  final Appointment? appointment;
  const _AppointmentDialog({required this.onSave, this.appointment});

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
    if (widget.appointment != null) {
      _doctorCtrl.text = widget.appointment!.doctorName;
      _specialtyCtrl.text = widget.appointment!.specialty;
      _notesCtrl.text = widget.appointment!.notes;
      _selectedDate = widget.appointment!.appointmentDateTime;
      _selectedTime = TimeOfDay(
        hour: widget.appointment!.appointmentDateTime.hour,
        minute: widget.appointment!.appointmentDateTime.minute,
      );
    } else {
      _selectedDate = DateTime.now();
      _selectedTime = TimeOfDay.now();
    }
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
    return Consumer<SettingsProvider>(
      builder: (context, sp, _) {
        final lang = sp.language;
        
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
                  widget.appointment != null 
                    ? AppTranslations.translate('edit_appointment', lang)
                    : AppTranslations.translate('add_appointment', lang),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                AppTranslations.translate('doctor_name', lang),
                lang == 'ar' ? 'د. محمد' : 'Dr. Mohammed',
                _doctorCtrl,
                icon: Icons.person
              ),
              const SizedBox(height: 12),
              _buildTextField(
                AppTranslations.translate('specialty', lang),
                lang == 'ar' ? 'مثال: باطنية، أسنان' : 'E.g.: Internal Medicine, Dentistry',
                _specialtyCtrl
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildDateField(lang),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTimeField(lang),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildMultilineField(
                AppTranslations.translate('notes', lang),
                lang == 'ar' ? 'اكتب ها الأسئلة التي تود طرحها على الطبيب' : 'Write questions you want to ask the doctor',
                _notesCtrl
              ),
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
                        final appointmentDateTime = DateTime(
                          _selectedDate.year,
                          _selectedDate.month,
                          _selectedDate.day,
                          _selectedTime.hour,
                          _selectedTime.minute,
                        );
                        widget.onSave(
                          _doctorCtrl.text.isEmpty 
                            ? AppTranslations.translate('doctor', lang)
                            : _doctorCtrl.text,
                          _specialtyCtrl.text.isEmpty 
                            ? AppTranslations.translate('specialty', lang)
                            : _specialtyCtrl.text,
                          appointmentDateTime,
                          _notesCtrl.text,
                        );
                        Navigator.pop(context);
                      },
                      child: Text(
                        widget.appointment != null 
                          ? AppTranslations.translate('update_appointment', lang) 
                          : AppTranslations.translate('save_appointment', lang)
                      ),
                    ),
                  ),
                ],
              ),
                ],
              ),
            ),
          ),
        );
      },
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

  Widget _buildDateField(String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppTranslations.translate('appointment_date', lang),
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)
        ),
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

  Widget _buildTimeField(String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppTranslations.translate('appointment_time', lang),
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)
        ),
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
