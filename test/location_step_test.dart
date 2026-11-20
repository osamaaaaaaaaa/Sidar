import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:skincare/Views/Onboarding/location_step.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('city data contains Arabic and English labels', () async {
    final json = await rootBundle.loadString('assets/data/cities.json');
    final data = jsonDecode(json) as Map<String, dynamic>;
    for (final cities in data.values) {
      for (final city in cities as List) {
        expect(city, hasLength(3));
        expect(city[1], matches(RegExp(r'[\u0600-\u06ff]')));
        expect(city[2], isNotEmpty);
      }
    }
    final egypt = data['EG'] as List;
    expect(egypt.firstWhere((city) => city[0] == 'Alexandria'), [
      'Alexandria',
      'الإسكندرية',
      'Alexandria',
    ]);
  });

  testWidgets('changing language updates a selected city label', (
    tester,
  ) async {
    var arabic = false;
    late StateSetter update;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return LocationStep(
                isArabic: arabic,
                country: 'SA',
                city: 'riyadh',
                onLocationChanged: (_, _) {},
                onContinue: () {},
              );
            },
          ),
        ),
      ),
    );
    expect(
      tester.widget<TextField>(find.byType(TextField).last).controller!.text,
      'Riyadh (Central)',
    );
    update(() => arabic = true);
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField).last).controller!.text,
      'الرياض (المنطقة الوسطى)',
    );
  });

  testWidgets('searches country and city without sharing a scroll controller', (
    tester,
  ) async {
    Get.locale = const Locale('en', 'US');
    String? country;
    String? city;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => LocationStep(
              isArabic: false,
              country: country,
              city: city,
              onLocationChanged: (newCountry, newCity) => setState(() {
                country = newCountry;
                city = newCity;
              }),
              onContinue: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byType(TextField).first);
    await tester.enterText(find.byType(TextField).first, 'Saudi Arabia');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saudi Arabia').last);
    await tester.pumpAndSettle();
    expect(country, 'SA');
    await tester.tap(find.byType(TextField).last);
    await tester.enterText(find.byType(TextField).last, 'Riyadh');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Riyadh (Central)').last);
    await tester.pumpAndSettle();
    expect(city, 'riyadh');
    expect(tester.takeException(), isNull);
  });
}
