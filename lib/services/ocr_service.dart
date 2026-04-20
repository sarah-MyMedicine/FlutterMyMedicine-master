import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb, debugPrint, compute;
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRResult {
  final String? name;
  final String? dose;
  final String imagePath;
  final String rawText;

  OCRResult({required this.imagePath, required this.rawText, this.name, this.dose});
}

String _normalizeOcrText(String text) {
  final digitMap = <String, String>{
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
  };

  var normalized = text;
  digitMap.forEach((from, to) {
    normalized = normalized.replaceAll(from, to);
  });

  // Common OCR punctuation/unit confusions.
  return normalized
      .replaceAll('，', ',')
      .replaceAll('．', '.')
      .replaceAll('。', '.')
      .replaceAll('·', '.')
      .replaceAll('mq', 'mg')
      .replaceAll('m9', 'mg')
      .replaceAll('rnL', 'mL')
      .replaceAll('rnl', 'ml')
      .replaceAll('μg', 'µg')
      .replaceAll('ug', 'µg');
}

bool _containsLetters(String input) {
  return RegExp(r'\p{L}', unicode: true).hasMatch(input);
}

// Runs the simple parsing heuristics in a background isolate.
Map<String?, String?> _parseOcrText(String full) {
  final normalized = _normalizeOcrText(full);

  final RegExp doseRegex = RegExp(
    r"(\d+(?:[.,]\d+)?\s*(?:mg|g|mcg|µg|ml|mL|units|iu|tablet(?:s)?|tab(?:s)?|capsule(?:s)?|cap(?:s)?))",
    caseSensitive: false,
  );
  final match = doseRegex.firstMatch(normalized);
  final String? dose = match?.group(0)?.trim();

  String? name;
  final lines = normalized.split(RegExp(r'\r?\n'));
  var bestScore = -1;

  for (final l in lines) {
    final trimmed = l.trim();
    if (trimmed.isEmpty) continue;

    // Remove detected dose-like tokens before evaluating potential name text.
    final candidate = trimmed.replaceAll(doseRegex, '').trim();
    if (candidate.isEmpty) continue;
    if (!_containsLetters(candidate)) continue;
    if (candidate.length > 80) continue;

    final lettersCount = RegExp(r'\p{L}', unicode: true)
        .allMatches(candidate)
        .length;
    final digitsCount = RegExp(r'\d').allMatches(candidate).length;

    // Prefer lines with more letters and fewer digits/noise.
    final score = (lettersCount * 2) - digitsCount;
    if (score > bestScore) {
      bestScore = score;
      name = candidate;
    }
  }

  if (name == null && lines.isNotEmpty) {
    final fallback = lines
        .map((e) => e.trim())
        .firstWhere((e) => e.isNotEmpty, orElse: () => '');
    name = fallback.isEmpty ? null : fallback;
  }

  return {'name': name, 'dose': dose};
}

class OcrService {
  final ImagePicker _picker = ImagePicker();

  /// Pick an image path (camera or gallery). Returns the local file path or null.
  Future<String?> pickImagePath({bool fromCamera = true}) async {
    // Only support OCR on mobile platforms (Android / iOS). Return null on desktop/web.
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      debugPrint('OcrService: OCR is only supported on Android/iOS.');
      return null;
    }

    // OCR quality is very sensitive to downscaling/compression.
    // Keep high detail on both platforms, while staying memory-safe.
    final bool isIos = Platform.isIOS;
    final int quality = fromCamera ? (isIos ? 100 : 95) : 95;
    final double maxDimension = isIos ? 2600 : 2200;

    final XFile? file = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: quality,
      maxWidth: maxDimension,
      maxHeight: maxDimension,
      preferredCameraDevice: CameraDevice.rear,
      requestFullMetadata: false,
    );
    return file?.path;
  }

  /// Run OCR on an existing file path (keeps heavy parsing off the UI isolate).
  Future<OCRResult?> extractFromFile(String path) async {
    if (path.isEmpty) return null;
    final inputImage = InputImage.fromFilePath(path);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      final String full = _normalizeOcrText(recognizedText.text);

      final parsed = await compute(_parseOcrText, full);
      final String? name = parsed['name'];
      final String? dose = parsed['dose'];

      return OCRResult(imagePath: path, rawText: full, name: name, dose: dose);
    } finally {
      textRecognizer.close();
    }
  }

  /// Convenience: pick and extract in one call (keeps backwards compatibility).
  Future<OCRResult?> pickImageAndExtract({bool fromCamera = true}) async {
    final path = await pickImagePath(fromCamera: fromCamera);
    if (path == null) return null;
    return await extractFromFile(path);
  }
}
