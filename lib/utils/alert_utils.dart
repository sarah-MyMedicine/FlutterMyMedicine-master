String extractAlertId(Map<String, dynamic> alert) {
  final candidates = <String?>[
    alert['_id']?.toString(),
    alert['id']?.toString(),
    alert['alertId']?.toString(),
  ];

  for (final candidate in candidates) {
    if (candidate != null && candidate.isNotEmpty) {
      return candidate;
    }
  }

  return '';
}
