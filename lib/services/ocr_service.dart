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

// Runs the simple parsing heuristics in a background isolate.
Map<String?, String?> _parseOcrText(String full) {
  final RegExp doseRegex = RegExp(r"(\d+(?:[.,]\d+)?\s*(?:mg|g|mcg|µg|ml|mL|units))",
      caseSensitive: false);
  final match = doseRegex.firstMatch(full);
  final String? dose = match?.group(0)?.trim();

  String? name;
  final lines = full.split(RegExp(r'\r?\n'));
  for (final l in lines) {
    final trimmed = l.trim();
    if (trimmed.isEmpty) continue;
    if (doseRegex.hasMatch(trimmed)) continue;
    if (RegExp(r'[A-Za-z]').hasMatch(trimmed) && trimmed.length <= 60) {
      name = trimmed;
      break;
    }
  }
  name ??= lines.isNotEmpty ? lines.first.trim() : null;

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

    final XFile? file = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1024,
      maxHeight: 1024,
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
      final String full = recognizedText.text;

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
