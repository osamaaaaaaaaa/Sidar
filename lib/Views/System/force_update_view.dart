import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:skincare/Services/app_config_service.dart';
import 'package:skincare/Services/app_feedback.dart';
import 'package:skincare/Utils/AppColors.dart';
import 'package:skincare/Utils/AppTheme.dart';
import 'package:skincare/Views/Splash.dart';

/// Full-screen force update gate that blocks app usage until the app is updated.
class ForceUpdateView extends StatefulWidget {
  final AppRemoteConfig config;
  final String currentVersion;

  const ForceUpdateView({
    super.key,
    required this.config,
    required this.currentVersion,
  });

  @override
  State<ForceUpdateView> createState() => _ForceUpdateViewState();
}

class _ForceUpdateViewState extends State<ForceUpdateView> {
  bool _isChecking = false;

  bool get _isArabic =>
      (Get.locale?.languageCode ?? 'ar').toLowerCase().startsWith('ar');

  Future<void> _recheckVersion() async {
    setState(() => _isChecking = true);
    try {
      final result = await AppConfigService.instance.checkStatus();
      if (!result.isForceUpdate && !result.isMaintenance) {
        Get.offAll(
          () => const SplashGateView(),
          transition: Transition.fadeIn,
          duration: const Duration(milliseconds: 400),
        );
        return;
      }

      AppFeedback.warning(
        _isArabic
            ? 'يرجى إكمال التحديث من المتجر أولاً لتتمكن من استخدام التطبيق.'
            : 'Please complete the update from the store first to use the app.',
        title: _isArabic ? 'تنبيه' : 'Notice',
      );
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isArabic
        ? widget.config.updateTitleAr
        : widget.config.updateTitleEn;
    final message = _isArabic
        ? widget.config.updateMessageAr
        : widget.config.updateMessageEn;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                const Spacer(flex: 1),

                // Central Medallion
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: AppColors.gold, width: 2.2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.28),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/sidar-emblem-clean.png',
                        width: 70,
                        height: 70,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.system_update_rounded,
                              size: 48,
                              color: AppColors.gold,
                            ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 26),

                // Update Required Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.rocket_launch_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isArabic
                            ? 'تحديث إجباري ضروري'
                            : 'Mandatory Update Required',
                        style: TextStyle(
                          fontFamily: AppTheme.appFontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Title
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTheme.headingStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),

                const SizedBox(height: 12),

                // Message & Version Compare Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.25),
                      width: 1.1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: AppTheme.bodyStyle(
                          fontSize: 13.5,
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.20),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text(
                                  _isArabic ? 'إصدارك الحالي' : 'Current',
                                  style: TextStyle(
                                    fontFamily: AppTheme.appFontFamily,
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.currentVersion,
                                  style: TextStyle(
                                    fontFamily: AppTheme.appFontFamily,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              height: 24,
                              width: 1,
                              color: AppColors.gold.withValues(alpha: 0.25),
                            ),
                            Column(
                              children: [
                                Text(
                                  _isArabic ? 'الإصدار الأدنى' : 'Required',
                                  style: TextStyle(
                                    fontFamily: AppTheme.appFontFamily,
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.config.minSupportedVersion,
                                  style: TextStyle(
                                    fontFamily: AppTheme.appFontFamily,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.oliveGreen,
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

                const Spacer(flex: 2),

                // Primary Action: Open Store to Update
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => AppConfigService.instance.openStoreUrl(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.oliveGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.download_rounded, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          _isArabic
                              ? 'تحديث التطبيق الآن'
                              : 'Update Application Now',
                          style: TextStyle(
                            fontFamily: AppTheme.appFontFamily,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Secondary Action: Re-check after updating
                TextButton(
                  onPressed: _isChecking ? null : _recheckVersion,
                  child: _isChecking
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _isArabic
                              ? 'التحقق بعد التحديث 🔄'
                              : 'Re-check after update 🔄',
                          style: TextStyle(
                            fontFamily: AppTheme.appFontFamily,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
