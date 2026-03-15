import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mymedicineapp/Pages/home.dart';
import 'package:mymedicineapp/Pages/onboarding_page.dart';
import 'package:mymedicineapp/Pages/language_selection_page.dart';
import 'package:mymedicineapp/Pages/login_page.dart';
import 'package:mymedicineapp/Pages/register_page.dart';
import 'package:mymedicineapp/Pages/caregiver_link_page.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/notification_service.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/push_notification_service.dart';
import 'providers/medication_provider.dart';
import 'providers/blood_pressure_provider.dart';
import 'providers/blood_sugar_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/appointment_provider.dart';
import 'providers/adherence_provider.dart';
import 'providers/user_provider.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
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

  final medicationProvider = MedicationProvider();
  await medicationProvider.load();
  debugPrint('[main] Medications loaded');

  final bloodPressureProvider = BloodPressureProvider();
  await bloodPressureProvider.load();
  debugPrint('[main] Blood pressure readings loaded');

  final bloodSugarProvider = BloodSugarProvider();
  await bloodSugarProvider.load();
  debugPrint('[main] Blood sugar readings loaded');

  final userProvider = UserProvider();
  await userProvider.loadUserFromStorage();
  debugPrint('[main] User data loaded');

  // Initialize push notifications (supports background/terminated delivery via FCM).
  await PushNotificationService().initialize(isLoggedIn: userProvider.isLoggedIn);
  debugPrint('[main] PushNotificationService initialized');
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider.value(value: userProvider),
        ChangeNotifierProvider.value(value: medicationProvider),
        ChangeNotifierProvider.value(value: bloodPressureProvider),
        ChangeNotifierProvider.value(value: bloodSugarProvider),
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

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  bool _isFirstTime = false;
  bool _isLanguageSelected = false;
  bool _isUserLoggedIn = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkFirstTime();
    _checkMissedDosesOnStartup();
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App came back to foreground, check for missed doses
      debugPrint('[main] App resumed, checking for missed doses');
      _checkMissedDoses();
    }
  }
  
  Future<void> _checkMissedDosesOnStartup() async {
    // Wait a bit for providers to fully initialize
    await Future.delayed(const Duration(seconds: 2));
    await _checkMissedDoses();
  }
  
  Future<void> _checkMissedDoses() async {
    try {
      final userProvider = context.read<UserProvider>();
      final medicationProvider = context.read<MedicationProvider>();
      
      if (userProvider.isLoggedIn && userProvider.isPatient) {
        final username = userProvider.username;
        debugPrint('[main] Checking missed doses for patient: $username');
        await medicationProvider.performMissedDoseCheck(username);
      }
    } catch (e) {
      debugPrint('[main] Error checking missed doses: $e');
    }
  }

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final languageSelected = prefs.getBool('language_selected') ?? false;
    final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
    final userLoggedIn = prefs.getString('username') != null;
    
    setState(() {
      _isLanguageSelected = languageSelected;
      _isFirstTime = !onboardingCompleted;
      _isUserLoggedIn = userLoggedIn;
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

    // Provide the navigatorKey early so taps can be flushed ASAP
    NotificationService().setNavigatorKey(_navigatorKey);

    Widget getInitialPage() {
      // Priority: Login > Language > Onboarding > Home
      if (!_isUserLoggedIn) {
        return const LoginPage();
      } else if (!_isLanguageSelected) {
        return const LanguageSelectionPage();
      } else if (_isFirstTime) {
        return const OnboardingPage();
      } else {
        return const HomePage();
      }
    }

    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, _) {
        return MaterialApp(
          navigatorKey: _navigatorKey,
          title: 'My Medicine',
          theme: AppTheme.theme(settingsProvider.themeColor),
          home: getInitialPage(),
          routes: {
            '/home': (context) => const HomePage(),
            '/onboarding': (context) => const OnboardingPage(),
            '/language': (context) => const LanguageSelectionPage(),
            '/login': (context) => const LoginPage(),
            '/register': (context) => const RegisterPage(),
            '/caregiver-link': (context) => const CaregiverLinkPage(),
          },
          builder: (context, child) {
            return Consumer<SettingsProvider>(
              builder: (context, settings, _) {
                return Directionality(
                  textDirection: settings.language == 'ar' ? TextDirection.rtl : TextDirection.ltr,
                  child: child!,
                );
              },
            );
          },
        );
      },
    );
  }
}


