import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../utils/translations.dart';

class BloodSugarReportModal extends StatelessWidget {
  final double avg;
  const BloodSugarReportModal({super.key, required this.avg});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, sp, child) {
        final lang = sp.language;
        
        return Directionality(
          textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          child: Padding(
            padding: MediaQuery.of(context).viewInsets,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    AppTranslations.translate('bs_report_title', lang),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text('${AppTranslations.translate('average', lang)}: ${avg.toStringAsFixed(1)} mg/dL'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(AppTranslations.translate('close', lang)),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}