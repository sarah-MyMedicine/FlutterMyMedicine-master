import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../providers/settings_provider.dart';
import '../utils/translations.dart';

class LabResult {
  final String imagePath;
  final String description;

  LabResult({required this.imagePath, required this.description});

  Map<String, dynamic> toJson() => {
    'imagePath': imagePath,
    'description': description,
  };

  factory LabResult.fromJson(Map<String, dynamic> json) => LabResult(
    imagePath: json['imagePath'] ?? '',
    description: json['description'] ?? '',
  );
}

class LabResultsPage extends StatefulWidget {
  const LabResultsPage({super.key});

  @override
  State<LabResultsPage> createState() => _LabResultsPageState();
}

class _LabResultsPageState extends State<LabResultsPage> {
  static const String _labResultsKey = 'lab_results';
  final List<LabResult> _labResults = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    final prefs = await SharedPreferences.getInstance();
    final resultsJson = prefs.getString(_labResultsKey);
    if (resultsJson == null || resultsJson.isEmpty) return;

    try {
      final List<dynamic> decoded = jsonDecode(resultsJson);
      final parsed = decoded
          .whereType<Map>()
          .map((item) => LabResult.fromJson(Map<String, dynamic>.from(item)))
          .where((item) => item.imagePath.isNotEmpty)
          .toList();

      if (!mounted) return;
      setState(() {
        _labResults
          ..clear()
          ..addAll(parsed);
      });
    } catch (e) {
      debugPrint('Failed to load lab results: $e');
    }
  }

  Future<void> _saveImages() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_labResultsKey, jsonEncode(_labResults.map((r) => r.toJson()).toList()));
  }

  Future<String> _persistImageLocally(String sourcePath) async {
    final sourceFile = File(sourcePath);
    final docsDir = await getApplicationDocumentsDirectory();
    final targetDir = Directory('${docsDir.path}${Platform.pathSeparator}lab_results_images');
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final extensionIndex = sourcePath.lastIndexOf('.');
    final extension = extensionIndex == -1 ? '.jpg' : sourcePath.substring(extensionIndex);
    final fileName = 'lab_${DateTime.now().millisecondsSinceEpoch}$extension';
    final targetPath = '${targetDir.path}${Platform.pathSeparator}$fileName';

    final copied = await sourceFile.copy(targetPath);
    return copied.path;
  }

  Future<void> _pickImage(ImageSource source) async {
    final lang = context.read<SettingsProvider>().language;
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        final persistentPath = await _persistImageLocally(image.path);

        // Show dialog to add description
        final description = await _showDescriptionDialog(context);
        if (description != null) {
          setState(() {
            _labResults.add(LabResult(
              imagePath: persistentPath,
              description: description,
            ));
          });
          await _saveImages();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppTranslations.translate('image_added_success', lang))),
            );
          }
        } else {
          try {
            final file = File(persistentPath);
            if (await file.exists()) {
              await file.delete();
            }
          } catch (e) {
            debugPrint('Failed to cleanup canceled lab image file: $e');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppTranslations.translate('error_adding_image', lang)}: $e')),
        );
      }
    }
  }

  Future<String?> _showDescriptionDialog(BuildContext context, {String? initialDescription}) async {
    final lang = context.read<SettingsProvider>().language;
    final controller = TextEditingController(text: initialDescription);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppTranslations.translate('add_description_dialog', lang)),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: AppTranslations.translate('description_notes', lang),
            hintText: AppTranslations.translate('example_complete_blood', lang),
            border: const OutlineInputBorder(),
          ),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppTranslations.translate('cancel', lang)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(AppTranslations.translate('save', lang)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteImage(int index) async {
    final lang = context.read<SettingsProvider>().language;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppTranslations.translate('delete_image_title', lang)),
        content: Text(AppTranslations.translate('confirm_delete_image', lang)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppTranslations.translate('cancel', lang)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppTranslations.translate('delete', lang)),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      final removedPath = _labResults[index].imagePath;
      setState(() {
        _labResults.removeAt(index);
      });

      try {
        final removedFile = File(removedPath);
        if (await removedFile.exists()) {
          await removedFile.delete();
        }
      } catch (e) {
        debugPrint('Failed to delete lab image file: $e');
      }

      await _saveImages();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppTranslations.translate('image_deleted_success', lang))),
        );
      }
    }
  }

  Future<void> _editDescription(int index) async {
    final lang = context.read<SettingsProvider>().language;
    final currentDescription = _labResults[index].description;
    final newDescription = await _showDescriptionDialog(context, initialDescription: currentDescription);
    if (newDescription != null) {
      setState(() {
        _labResults[index] = LabResult(
          imagePath: _labResults[index].imagePath,
          description: newDescription,
        );
      });
      await _saveImages();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppTranslations.translate('description_updated_success', lang))),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    final lang = context.read<SettingsProvider>().language;
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: Text(AppTranslations.translate('camera', lang)),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(AppTranslations.translate('gallery', lang)),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _viewImage(int index) {
    final lang = context.read<SettingsProvider>().language;
    final result = _labResults[index];
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(AppTranslations.translate('view_result', lang)),
            backgroundColor: Colors.black,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _editDescription(index);
                },
              ),
            ],
          ),
          backgroundColor: Colors.black,
          body: Column(
            children: [
              Expanded(
                child: Center(
                  child: InteractiveViewer(
                    child: Image.file(File(result.imagePath)),
                  ),
                ),
              ),
              if (result.description.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.black87,
                  child: Text(
                    result.description,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, sp, child) {
        final lang = sp.language;
        return Directionality(
          textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: Icon(lang == 'ar' ? Icons.arrow_forward : Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Text(AppTranslations.translate('lab_results_title', lang)),
            ),
            body: _labResults.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_not_supported,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppTranslations.translate('no_lab_results_found', lang),
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppTranslations.translate('add_first_result', lang),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: _labResults.length,
                    itemBuilder: (context, index) {
                      final result = _labResults[index];
                      return Card(
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Stack(
                                children: [
                                  GestureDetector(
                                    onTap: () => _viewImage(index),
                                    child: Image.file(
                                      File(result.imagePath),
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.grey.shade200,
                                          child: const Center(
                                            child: Icon(
                                              Icons.broken_image,
                                              size: 50,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.6),
                                            shape: BoxShape.circle,
                                          ),
                                          child: IconButton(
                                            icon: const Icon(
                                              Icons.edit,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                            padding: const EdgeInsets.all(4),
                                            constraints: const BoxConstraints(),
                                            onPressed: () => _editDescription(index),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.6),
                                            shape: BoxShape.circle,
                                          ),
                                          child: IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                            padding: const EdgeInsets.all(4),
                                            constraints: const BoxConstraints(),
                                            onPressed: () => _deleteImage(index),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (result.description.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.all(8),
                                color: Colors.grey.shade100,
                                child: Text(
                                  result.description,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
            floatingActionButton: FloatingActionButton(
              onPressed: _showImageSourceDialog,
              tooltip: AppTranslations.translate('add_image_button', lang),
              child: const Icon(Icons.add),
            ),
          ),
        );
      },
    );
  }
}
