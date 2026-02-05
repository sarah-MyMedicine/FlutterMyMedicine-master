import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mymedicineapp/Pages/home.dart';
import 'package:mymedicineapp/Pages/onboarding_page.dart';
import 'services/notification_service.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'providers/medication_provider.dart';
import 'providers/blood_pressure_provider.dart';
import 'providers/blood_sugar_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/appointment_provider.dart';
import 'providers/adherence_provider.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('[main] Initializing services...');
  
  // Initialize API Service
  await ApiService().init();
  debugPrint('[main] ApiService initialized');
  
  // Initialize Notification Service
  await NotificationService().init();
  debugPrint('[main] NotificationService initialized');
  
  // Initialize providers
  final settingsProvider = SettingsProvider();
  await settingsProvider.load();
  debugPrint('[main] Settings loaded');
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => MedicationProvider()),
        ChangeNotifierProvider(create: (_) => BloodPressureProvider()),
        ChangeNotifierProvider(create: (_) => BloodSugarProvider()),
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider(create: (_) => AppointmentProvider()),
        ChangeNotifierProvider(create: (_) => AdherenceProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  bool _isFirstTime = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkFirstTime();
  }

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
    setState(() {
      _isFirstTime = !onboardingCompleted;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    // Debug auto-add disabled: adding meds on app start has caused heavy startup activity in some environments.
    // If you need it for testing, re-enable manually and use a lightweight schedule.
    // Example to re-enable (debug only):
    // assert(() {
    //   WidgetsBinding.instance.addPostFrameCallback((_) {
    //     try {
    //       final medProv = Provider.of<MedicationProvider>(context, listen: false);
    //       final now = DateTime.now().add(const Duration(minutes: 1));
    //       final start = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    //       medProv.add('DebugMed', '1 tablet', intervalHours: 6, startTime: start);
    //     } catch (_) {}
    //   });
    //   return true;
    // }());

    // Provide the navigatorKey early so taps can be flushed ASAP
    NotificationService().setNavigatorKey(_navigatorKey);

    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'My Medicine',
      theme: AppTheme.theme,
      home: _isFirstTime ? const OnboardingPage() : const HomePage(),
      routes: {
        '/home': (context) => const HomePage(),
        '/onboarding': (context) => const OnboardingPage(),
      },
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
    );
  }
}
