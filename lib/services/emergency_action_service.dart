class EmergencyActionService {
  static String? resolveTargetUsername({
    required bool isPatient,
    required String? currentUsername,
    required String? selectedPatientUsername,
  }) {
    if (isPatient) {
      final username = currentUsername?.trim().toLowerCase();
      return (username != null && username.isNotEmpty) ? username : null;
    }

    final username = selectedPatientUsername?.trim().toLowerCase();
    return (username != null && username.isNotEmpty) ? username : null;
  }
}
