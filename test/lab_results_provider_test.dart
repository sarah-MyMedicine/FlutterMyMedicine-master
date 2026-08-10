import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mymedicineapp/providers/lab_results_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('persists lab results across app restarts', () async {
    final firstSession = LabResultsProvider();
    await firstSession.load();

    await firstSession.add(
      LabResult(
        imagePath: '/tmp/lab_result.jpg',
        description: 'CBC report',
        imageBase64: 'abc123',
      ),
    );

    final secondSession = LabResultsProvider();
    await secondSession.load();

    expect(secondSession.entries.length, 1);
    expect(secondSession.entries.first.description, 'CBC report');
    expect(secondSession.entries.first.imageBase64, 'abc123');
  });
}
