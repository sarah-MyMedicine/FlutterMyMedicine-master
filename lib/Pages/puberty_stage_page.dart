import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../utils/translations.dart';

class PubertyStageInfoPage extends StatelessWidget {
  const PubertyStageInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, sp, child) {
        final lang = sp.language;
        return Directionality(
          textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            appBar: AppBar(
              title: Text(AppTranslations.translate('puberty_stage', lang)),
              backgroundColor: const Color(0xFF1EBEA6),
              foregroundColor: Colors.white,
              leading: IconButton(
                icon: Icon(lang == 'ar' ? Icons.arrow_forward : Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            backgroundColor: const Color(0xFFF5F5F5),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              // Header section with butterfly
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFDE6F0), Color(0xFFFFF0F7)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: lang == 'ar' ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                            children: [
                              Text(
                                AppTranslations.translate('puberty_bloom', lang),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFD81B60),
                                ),
                                textAlign: lang == 'ar' ? TextAlign.left : TextAlign.right,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                AppTranslations.translate('first_steps_womanhood', lang),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFFD81B60),
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: lang == 'ar' ? TextAlign.left : TextAlign.right,
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.flutter_dash,
                          size: 48,
                          color: Color(0xFFD81B60),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppTranslations.translate('puberty_natural_transition', lang),
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Personal hygiene section
              _buildInfoCard(
                context,
                lang,
                icon: Icons.self_improvement,
                iconColor: const Color(0xFF42A5F5),
                title: AppTranslations.translate('personal_hygiene', lang),
                content: AppTranslations.translate('personal_hygiene_desc', lang),
                subtitle: AppTranslations.translate('daily_routine_suggested', lang),
                bulletPoints: [
                  AppTranslations.translate('daily_shower', lang),
                  AppTranslations.translate('use_deodorant', lang),
                  AppTranslations.translate('change_underwear', lang),
                ],
              ),
              const SizedBox(height: 16),

              // Nutrition section
              _buildInfoCard(
                context,
                lang,
                icon: Icons.restaurant,
                iconColor: const Color(0xFFEC407A),
                title: AppTranslations.translate('menstrual_cycle_care', lang),
                content: AppTranslations.translate('menstrual_cycle_desc', lang),
                subtitle: AppTranslations.translate('golden_rules', lang),
                bulletPoints: [
                  AppTranslations.translate('regular_change', lang),
                  AppTranslations.translate('hygiene_during_change', lang),
                  AppTranslations.translate('choose_right_type', lang),
                ],
              ),
              const SizedBox(height: 16),

              // Tips section
              _buildTipsCard(context, lang),
              const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    String lang, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
    String? subtitle,
    List<String>? bulletPoints,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE91E63), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD81B60),
                  ),
                  textAlign: lang == 'ar' ? TextAlign.right : TextAlign.left,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Colors.black87,
            ),
            textAlign: TextAlign.justify,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: lang == 'ar' ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: lang == 'ar' ? TextAlign.right : TextAlign.left,
                  ),
                  if (bulletPoints != null) ...[
                    const SizedBox(height: 12),
                    ...bulletPoints.map((point) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ', style: TextStyle(fontSize: 16)),
                              Expanded(
                                child: Text(
                                  point,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    height: 1.5,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTipsCard(BuildContext context, String lang) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9E6),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '👏',
                style: TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
              Text(
                AppTranslations.translate('tips_boost_confidence', lang),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF6F00),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTipItem(context, lang, '💖', AppTranslations.translate('love_new_appearance', lang)),
          const SizedBox(height: 12),
          _buildTipItem(context, lang, '💖', AppTranslations.translate('dont_compare', lang)),
          const SizedBox(height: 12),
          _buildTipItem(context, lang, '💖', AppTranslations.translate('talk_to_family', lang)),
        ],
      ),
    );
  }

  Widget _buildTipItem(BuildContext context, String lang, String emoji, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
