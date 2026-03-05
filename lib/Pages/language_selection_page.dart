import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/settings_provider.dart';

class LanguageSelectionPage extends StatelessWidget {
  const LanguageSelectionPage({super.key});

  Future<void> _selectLanguage(BuildContext context, String language) async {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    await settingsProvider.setLanguage(language);
    
    // Mark language selection as completed
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('language_selected', true);
    
    if (context.mounted) {
      Navigator.of(context).pushReplacementNamed('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF57B6A8),
              const Color(0xFF36BBA0),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.language,
                    size: 80,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'اختر اللغة / Choose Language',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  _buildLanguageCard(
                    context: context,
                    language: 'ar',
                    title: 'العربية',
                    subtitle: 'اللغة العربية',
                    icon: '🇸🇦',
                  ),
                  const SizedBox(height: 16),
                  _buildLanguageCard(
                    context: context,
                    language: 'en',
                    title: 'English',
                    subtitle: 'English Language',
                    icon: '🇬🇧',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageCard({
    required BuildContext context,
    required String language,
    required String title,
    required String subtitle,
    required String icon,
  }) {
    return InkWell(
      onTap: () => _selectLanguage(context, language),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(
              icon,
              style: const TextStyle(fontSize: 40),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF36BBA0),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF36BBA0),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
