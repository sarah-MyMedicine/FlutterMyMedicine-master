// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mymedicineapp/main.dart';
import 'package:mymedicineapp/providers/adherence_provider.dart';
import 'package:mymedicineapp/providers/medication_provider.dart';
import 'package:mymedicineapp/providers/settings_provider.dart';
import 'package:mymedicineapp/providers/user_provider.dart';
import 'package:mymedicineapp/services/notification_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('patient-specific alert titles include the patient name', () {
    expect(
      NotificationService.buildPatientAlertTitle(
        patientName: 'Ahmed',
        isEmergency: false,
        lang: 'en',
      ),
      'Missed dose alert for Ahmed',
    );

    expect(
      NotificationService.buildPatientAlertTitle(
        patientName: 'Ahmed',
        isEmergency: true,
        lang: 'ar',
      ),
      'تنبيه طارئ: Ahmed',
    );
  });

  test('missed doses are stored as not-taken adherence logs', () async {
    final provider = AdherenceProvider();
    await provider.clearAll();

    await provider.recordMissed(
      medicationName: 'Aspirin',
      dose: '1 tablet',
      missedAt: DateTime(2026, 1, 2, 8, 0),
    );

    expect(provider.logs.length, 1);
    expect(provider.logs.first.taken, isFalse);
    expect(provider.logs.first.medicationName, 'Aspirin');
  });

  testWidgets('app builds without crashing and shows a material app', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ChangeNotifierProvider(create: (_) => UserProvider()),
          ChangeNotifierProvider(create: (_) => MedicationProvider()),
        ],
        child: const MyApp(),
      ),
    );

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
