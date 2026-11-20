import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skincare/Views/Settings/Settings.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _SettingsWithoutNetwork extends SettingsController {
  // The test controls loading state without starting the network request.
  @override
  // ignore: must_call_super
  void onInit() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      anonKey: 'test',
    );
  });

  testWidgets('account loading uses shimmer instead of a spinner', (
    tester,
  ) async {
    Get.testMode = true;
    final controller = Get.put<SettingsController>(_SettingsWithoutNetwork());
    controller.isProfileLoading.value = true;
    await tester.pumpWidget(GetMaterialApp(home: SettingsView()));
    expect(find.byType(ShaderMask), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Sidar User'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    Get.reset();
  });
}
