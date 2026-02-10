import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../components/medication_form_modal.dart';
import '../providers/medication_provider.dart';
import '../services/ocr_service.dart';
import '../Pages/settings_page.dart';

class Footer extends StatelessWidget {
  const Footer({super.key});

  Future<void> _showAddOptions(BuildContext context) async {
    debugPrint('Footer: showAddOptions called');
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Add manually'),
              onTap: () {
                Navigator.of(ctx).pop();
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => MedicationFormModal(
                    initialIntervalHours: null, // force explicit user selection
                    onSave: (name, dose, {imagePath, intervalHours, startTime, startDate}) {
                      Provider.of<MedicationProvider>(context, listen: false)
                          .add(name, dose, imagePath: imagePath, intervalHours: intervalHours ?? 24, startTime: startTime, startDate: startDate);
                    },
                  ),
                );
              },

            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Add from photo (camera)'),
              onTap: () async {
                Navigator.of(ctx).pop();
                await _handleAddFromPhoto(context, fromCamera: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Add from photo (gallery)'),
              onTap: () async {
                Navigator.of(ctx).pop();
                await _handleAddFromPhoto(context, fromCamera: false);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAddFromPhoto(BuildContext context,
      {required bool fromCamera}) async {
    final OcrService ocr = OcrService();
    // First let the user pick an image and get its path.
    final String? path = await ocr.pickImagePath(fromCamera: fromCamera);
    if (path == null) return;
    if (!context.mounted) return;

    // Show a blocking progress dialog while OCR + parsing runs.
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final result = await ocr.extractFromFile(path);

    // Close progress dialog
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();

    if (result == null) return;
    if (!context.mounted) return;

    // Show pre-filled form allowing users to confirm/adjust detected fields
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => MedicationFormModal(
          initialName: result.name,
          initialDose: result.dose,
          initialImagePath: result.imagePath,
          initialIntervalHours: null, // require user choose interval after OCR
          onSave: (name, dose, {imagePath, intervalHours, startTime, startDate}) {
            Provider.of<MedicationProvider>(context, listen: false)
                .add(name, dose, imagePath: imagePath, intervalHours: intervalHours ?? 24, startTime: startTime, startDate: startDate);
          }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () {},
              icon: Icon(
                Icons.home,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Tooltip(
              message: 'Add',
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: () {
                    debugPrint('Footer: + tapped');
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening add options...')));
                    _showAddOptions(context);
                  },

                  customBorder: const CircleBorder(),
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withAlpha(89),
                            blurRadius: 8,
                          ),
                        ],
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('قريبا', textAlign: TextAlign.center),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: Icon(
                Icons.shopping_cart,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                );
              },
              icon: Icon(
                Icons.person,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              tooltip: 'اعداداتي',
            ),
          ],
        ),
      ),
    );
  }
}
