import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Appointment {
  final String id;
  final String doctorName;
  final String specialty;
  final DateTime appointmentDateTime;
  final String notes;

  Appointment({
    required this.id,
    required this.doctorName,
    required this.specialty,
    required this.appointmentDateTime,
    required this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'doctorName': doctorName,
      'specialty': specialty,
      'appointmentDateTime': appointmentDateTime.toIso8601String(),
      'notes': notes,
    };
  }

  factory Appointment.fromMap(Map<String, dynamic> map) {
    return Appointment(
      id: map['id'] ?? '',
      doctorName: map['doctorName'] ?? '',
      specialty: map['specialty'] ?? '',
      appointmentDateTime: DateTime.parse(map['appointmentDateTime'] ?? DateTime.now().toIso8601String()),
      notes: map['notes'] ?? '',
    );
  }
}

class AppointmentProvider extends ChangeNotifier {
  List<Appointment> _appointments = [];

  List<Appointment> get appointments => List.unmodifiable(_appointments);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final appointmentStrings = prefs.getStringList('appointments') ?? [];
    _appointments = [];
    for (final str in appointmentStrings) {
      try {
        final parts = str.split('|||');
        if (parts.length == 5) {
          _appointments.add(
            Appointment(
              id: parts[0],
              doctorName: parts[1],
              specialty: parts[2],
              appointmentDateTime: DateTime.parse(parts[3]),
              notes: parts[4],
            ),
          );
        }
      } catch (e) {
        debugPrint('Error parsing appointment: $e');
      }
    }
    notifyListeners();
  }

  Future<void> add(String doctorName, String specialty, DateTime appointmentDateTime, String notes) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final appointment = Appointment(
      id: id,
      doctorName: doctorName,
      specialty: specialty,
      appointmentDateTime: appointmentDateTime,
      notes: notes,
    );
    _appointments.add(appointment);
    await _saveToPrefs();
    notifyListeners();
  }

  Future<void> delete(String id) async {
    _appointments.removeWhere((a) => a.id == id);
    await _saveToPrefs();
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final appointmentStrings = _appointments
        .map((a) => '${a.id}|||${a.doctorName}|||${a.specialty}|||${a.appointmentDateTime.toIso8601String()}|||${a.notes}')
        .toList();
    await prefs.setStringList('appointments', appointmentStrings);
  }
}
