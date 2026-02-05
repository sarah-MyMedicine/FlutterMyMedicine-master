import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/settings_provider.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final userName = settingsProvider.name;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildPage(
                    icon: Icons.waving_hand,
                    iconColor: Colors.amber,
                    content:
                        'هلو $userName،\n\nكلش فرحنا بوجودك ويانا! نورت تطبيق دوائي\n\nإحنا نعرف إن الالتزام بالأدوية ومتابعة القراءات مو شغلة سهلة وتدوّخ، ولهذا سوينا هذا التطبيق حتى نكون وياك خطوة بخطوة ونشيل عنك هذا الهم.',
                  ),
                  _buildPage(
                    icon: Icons.medical_services,
                    iconColor: Colors.green,
                    title: 'شنو اللي راح تحصله ويانا؟',
                    content:
                        '📱 تذكير ذكي بمواعيد ادويتك وما تدوخ بالوقت، إحنا نذكرك بالدقيقة والثانية.\n\n👨‍👩‍👧‍👦 أهلك وياك: تكدر تخلي عائلتك يشاركونك الالتزام ويطمنون عليك.\n\n🔒 خصوصية فول: بياناتك مشفرة ومحد يشوفها غيرك، يعني مأمن تماماً.\n\n📊 تقارير سهلة: بضغطة زر وحدة، سوي تقرير لضغطك وسكرك وشوفه لطبيبك.',
                  ),
                  _buildPage(
                    icon: Icons.rocket_launch,
                    iconColor: Colors.blue,
                    title: 'هسة شنو المطلوب منك؟',
                    content:
                        'بس افتح التطبيق، ضيف ادويتك ومواعيد اخذها، وخلي الباقي علينا.\n\nإذا عندك أي سؤال أو استفسار، إحنا موجودين بالخدمة بأي وقت.\n\nدمت بصحة وعافية،\nفريق تطبيق دوائي 🌸',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      3,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentPage > 0)
                        OutlinedButton(
                          onPressed: _previousPage,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                          ),
                          child: const Text(
                            'خلف',
                            style: TextStyle(fontSize: 16),
                          ),
                        )
                      else
                        const SizedBox(width: 100),
                      ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          _currentPage < 2 ? 'التالي' : 'ابدأ',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage({
    required IconData icon,
    required Color iconColor,
    String? title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 80,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 32),
          if (title != null) ...[
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
          ],
          Text(
            content,
            style: const TextStyle(
              fontSize: 18,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
