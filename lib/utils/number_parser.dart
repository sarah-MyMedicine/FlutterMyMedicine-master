String normalizeLocalizedDigits(String input) {
  const map = <String, String>{
    '٠': '0',
    '١': '1',
    '٢': '2',
    '٣': '3',
    '٤': '4',
    '٥': '5',
    '٦': '6',
    '٧': '7',
    '٨': '8',
    '٩': '9',
    '۰': '0',
    '۱': '1',
    '۲': '2',
    '۳': '3',
    '۴': '4',
    '۵': '5',
    '۶': '6',
    '۷': '7',
    '۸': '8',
    '۹': '9',
  };

  var out = input;
  map.forEach((from, to) {
    out = out.replaceAll(from, to);
  });
  return out;
}

int? tryParseIntLocalized(String? input) {
  if (input == null) return null;
  final normalized = normalizeLocalizedDigits(input).trim();
  return int.tryParse(normalized);
}
