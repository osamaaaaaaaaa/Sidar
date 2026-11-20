import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skincare/Services/scan_controller.dart';
import 'package:skincare/Views/Home/scan_city_field.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      anonKey: 'test',
    );
  });

  testWidgets('shows saved city and selects a city from the country list', (
    tester,
  ) async {
    final controller = ScanController();
    controller.locationText.value = 'SA';
    controller.selectedCity.value = 'jeddah';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScanCityField(controller: controller, isArabic: true),
        ),
      ),
    );
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'جدة (المنطقة الغربية)',
    );
    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'الدمام');
    await tester.pumpAndSettle();
    await tester.tap(find.text('الدمام (المنطقة الشرقية)').last);
    await tester.pumpAndSettle();
    expect(controller.selectedCity.value, 'dammam');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.onClose();
  });

  testWidgets('shows cities for the account country', (tester) async {
    final controller = ScanController();
    controller.locationText.value = 'EG';
    controller.selectedCity.value = 'Cairo';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScanCityField(
            controller: controller,
            isArabic: false,
            cityData: Future.value({
              'EG': [
                ['Cairo', 'القاهرة', 'Cairo'],
                ['Alexandria', 'الإسكندرية', 'Alexandria'],
              ],
              'FR': [
                ['Paris', 'باريس', 'Paris'],
              ],
            }),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Cairo',
    );
    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'Alexandria');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alexandria').last);
    await tester.pumpAndSettle();
    expect(controller.selectedCity.value, 'Alexandria');
    await tester.pumpWidget(const SizedBox.shrink());
    controller.onClose();
  });
}
