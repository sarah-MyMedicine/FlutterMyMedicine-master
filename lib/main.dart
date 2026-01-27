import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mymedicineapp/Pages/home.dart';
import 'services/notification_service.dart';
import 'providers/medication_provider.dart';
import 'providers/blood_pressure_provider.dart';
import 'providers/blood_sugar_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/appointment_provider.dart';
import 'providers/adherence_provider.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('[main] Initializing NotificationService...');
  await NotificationService().init();
  debugPrint('[main] NotificationService initialized successfully');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MedicationProvider()),
        ChangeNotifierProvider(create: (_) => BloodPressureProvider()),
        ChangeNotifierProvider(create: (_) => BloodSugarProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => AppointmentProvider()),
        ChangeNotifierProvider(create: (_) => AdherenceProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  // This widget is the root of your application.
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
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
      home: const HomePage(),
    );
  }
}
