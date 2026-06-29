// ignore_for_file: use_key_in_widget_constructors, camel_case_types

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:skincare/Controllers/HomeController.dart';
import 'package:skincare/Localization/app_tramsaltion.dart';
import 'package:skincare/Services/supabase_config.dart';
import 'package:skincare/Utils/AppColors.dart';
import 'package:skincare/Utils/AppTheme.dart';
import 'package:skincare/Services/routine_notification_service.dart';
import 'package:skincare/Views/Splash.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
  try {
    await RoutineNotificationService.instance.init();
  } catch (_) {}
  runApp(app());
}

class app extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      translations: AppTransaltion(),
      locale: const Locale('ar', 'SA'),
      fallbackLocale: const Locale('ar', 'SA'),
      builder: (context, child) {
        final locale = Get.locale ?? const Locale('ar', 'SA');
        final isArabic = locale.languageCode.toLowerCase() == 'ar';
        final fontFamily = isArabic
            ? AppTheme.arabicFontFamily
            : AppTheme.englishFontFamily;
        final baseTheme = Theme.of(context);

        return Theme(
          data: baseTheme.copyWith(
            textTheme: baseTheme.textTheme.apply(
              fontFamily: fontFamily,
              bodyColor: AppColors.textPrimary,
              displayColor: AppColors.textPrimary,
            ),
            primaryTextTheme: baseTheme.primaryTextTheme.apply(
              fontFamily: fontFamily,
              bodyColor: AppColors.textPrimary,
              displayColor: AppColors.textPrimary,
            ),
          ),
          child: Directionality(
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      theme: ThemeData(
        brightness: Brightness.light,
        fontFamily: AppTheme.arabicFontFamily,
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.primary,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: AppColors.surface,
          error: AppColors.error,
        ),
        cardColor: AppColors.surface,
        dividerColor: AppColors.borderSoft,
        textTheme: ThemeData.light().textTheme.apply(
          fontFamily: AppTheme.arabicFontFamily,
          bodyColor: AppColors.textPrimary,
          displayColor: AppColors.textPrimary,
        ),
      ),
      initialBinding: bindings(),
      home: const SplashGateView(),
    );
  }
}

class bindings extends Bindings {
  @override
  void dependencies() {
    Get.put(HomeController(), permanent: true);
  }
}
