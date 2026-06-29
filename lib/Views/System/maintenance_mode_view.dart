import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:skincare/Services/app_config_service.dart';
import 'package:skincare/Services/app_feedback.dart';
import 'package:skincare/Utils/AppColors.dart';
import 'package:skincare/Utils/AppTheme.dart';
import 'package:skincare/Views/Splash.dart';

/// Full-screen luxury maintenance mode gate that blocks access when maintenance_mode is enabled.
class MaintenanceModeView extends StatefulWidget {
  final AppRemoteConfig config;

  const MaintenanceModeView({super.key, required this.config});

  @override
  State<MaintenanceModeView> createState() => _MaintenanceModeViewState();
}

class _MaintenanceModeViewState extends State<MaintenanceModeView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  bool _isChecking = false;

  bool get _isArabic =>
      (Get.locale?.languageCode ?? 'ar').toLowerCase().startsWith('ar');

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkMaintenanceStatus() async {
    setState(() => _isChecking = true);
    try {
      final result = await AppConfigService.instance.checkStatus();
      if (!result.isMaintenance) {
        Get.offAll(
          () => const SplashGateView(),
          transition: Transition.fadeIn,
          duration: const Duration(milliseconds: 400),
        );
        return;
      }

      AppFeedback.warning(
        _isArabic
            ? 'نظام سدر ما زال قيد التحسينات الدورية، سنعود للعمل قريباً جداً.'
            : 'SIDAR is still under scheduled improvements. We will be back shortly.',
        title: _isArabic ? 'الصيانة مستمرة' : 'Still Under Maintenance',
      );
    } catch (_) {
      AppFeedback.error(
        _isArabic
            ? 'تعذر الاتصال بالخادم، يرجى المحاولة بعد قليل.'
            : 'Could not connect to server. Please try again shortly.',
        title: _isArabic ? 'تنبيه' : 'Notice',
      );
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isArabic
        ? widget.config.maintenanceTitleAr
        : widget.config.maintenanceTitleEn;
    final message = _isArabic
        ? widget.config.maintenanceMessageAr
        : widget.config.maintenanceMessageEn;

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

                // Animated Medallion with pulsing glow
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final pulse = _pulseController.value;
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 140 + (pulse * 14),
                          height: 140 + (pulse * 14),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.gold.withValues(
                              alpha: 0.12 - (pulse * 0.06),
                            ),
                          ),
                        ),
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(
                              color: AppColors.gold,
                              width: 2.2,
                            ),
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
                                      Icons.build_circle_rounded,
                                      size: 48,
                                      color: AppColors.gold,
                                    ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 28),

                // Maintenance Badge Pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5A93C).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: const Color(0xFFE5A93C).withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFE5A93C),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isArabic
                            ? 'أعمال الصيانة المجدولة'
                            : 'Scheduled Maintenance',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB57D1D),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Main Title
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

                // Message Glass Card
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
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Divider(
                        height: 1,
                        color: AppColors.gold.withValues(alpha: 0.14),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.verified_user_outlined,
                            size: 16,
                            color: AppColors.oliveGreen,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isArabic
                                ? 'بياناتك وسجلاتك الطبية محفوظة بأمان كامل'
                                : 'Your clinical records are completely secure',
                            style: TextStyle(
                              fontFamily: AppTheme.appFontFamily,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.oliveGreen,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // Refresh Status Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isChecking ? null : _checkMaintenanceStatus,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.oliveGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    child: _isChecking
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.refresh_rounded, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                _isArabic
                                    ? 'التحقق من حالة النظام الآن'
                                    : 'Check System Status Now',
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

                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
