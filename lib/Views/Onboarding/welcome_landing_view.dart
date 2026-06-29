import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:skincare/Services/app_config_service.dart';
import 'package:skincare/Services/app_feedback.dart';
import 'package:skincare/Utils/AppColors.dart';
import 'package:skincare/Utils/AppTheme.dart';
import 'package:skincare/Views/Auth/Login.dart';
import 'package:skincare/Views/Onboarding/ivory_motion_background.dart';
import 'package:skincare/Views/Onboarding/onboarding_questionnaire_view.dart';
import 'package:url_launcher/url_launcher.dart';

class WelcomeLandingView extends StatefulWidget {
  const WelcomeLandingView({super.key});

  @override
  State<WelcomeLandingView> createState() => _WelcomeLandingViewState();
}

class _WelcomeLandingViewState extends State<WelcomeLandingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  bool get _isArabic =>
      (Get.locale?.languageCode ?? 'ar').toLowerCase().startsWith('ar');

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggleLanguage() {
    final next = _isArabic
        ? const Locale('en', 'US')
        : const Locale('ar', 'SA');
    Get.updateLocale(next);
  }

  Future<void> _openLegalDocument() async {
    try {
      final config = await AppConfigService.instance.fetchRemoteConfig(
        forceRefresh: true,
      );
      final uri = Uri.tryParse(config.privacyPolicyUrl.trim());
      if (uri == null || !['https', 'http'].contains(uri.scheme)) {
        throw const FormatException();
      }
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw const FormatException();
      }
    } catch (_) {
      AppFeedback.error(
        _isArabic
            ? 'رابط الشروط وسياسة الخصوصية غير متاح حاليًا.'
            : 'The terms and privacy link is currently unavailable.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IvoryMotionBackground(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              // Top Bar: Language toggle
              _buildTopBar(),

              const Spacer(flex: 2),

              // Center Brand Emblem & Title with Motion Animation
              _buildBrandSection(),

              const Spacer(flex: 3),

              // Bottom Actions
              _buildActionSection(),

              const SizedBox(height: 12),

              // Legal / Terms note
              _buildLegalFooter(),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // Language Toggle button matching video "اللغه English"
        InkWell(
          onTap: _toggleLanguage,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: AppColors.oliveGreen.withValues(alpha: 0.35),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.oliveGreen.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.language_rounded,
                  size: 19,
                  color: AppColors.oliveGreen,
                ),
                const SizedBox(width: 8),
                Text(
                  _isArabic ? 'اللغه English' : 'العربية',
                  style: AppTheme.bodyStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.oliveGreen,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBrandSection() {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, _) {
        final t = _animController.value;
        final pulse = 1.0 + (math.sin(t * 2 * math.pi) * 0.035);
        final glowAlpha = 0.25 + (math.sin(t * 2 * math.pi) * 0.10);

        return Column(
          children: [
            // Glowing Animated Emblem with breathing pulse
            Transform.scale(
              scale: pulse,
              child: Container(
                width: 142,
                height: 142,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: glowAlpha),
                      blurRadius: 36,
                      offset: const Offset(0, 10),
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: AppColors.oliveGreen.withValues(alpha: 0.12),
                      blurRadius: 18,
                    ),
                  ],
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.70),
                    width: 2.2,
                  ),
                ),
                child: Center(
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/sidar-emblem-clean.png',
                      width: 110,
                      height: 110,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.spa_rounded,
                        size: 54,
                        color: AppColors.oliveGreen,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            Text(
              'SIDAR AI',
              style: AppTheme.headingStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                letterSpacing: 3.0,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _isArabic
                    ? 'مستقبل العناية الفائقة ببشرتك وشعرك يبدأ هنا'
                    : 'The future of your skin and hair intelligence starts here',
                textAlign: TextAlign.center,
                style: AppTheme.bodyStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionSection() {
    return Column(
      children: [
        // Primary Button: "Get Started" / "ابدأ الآن" using Olive Green #718568
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: () => Get.to(() => const OnboardingQuestionnaireView()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.oliveGreen,
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: AppColors.oliveGreen.withValues(alpha: 0.35),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: Text(
              _isArabic ? 'ابدأ الآن' : 'Get Started',
              style: AppTheme.bodyStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Secondary Button: "I already have an account" / "لدي حساب بالفعل"
        SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton(
            onPressed: () => Get.to(() => const LoginView()),
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.90),
              foregroundColor: AppColors.oliveGreen,
              side: const BorderSide(color: AppColors.oliveGreen, width: 1.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: Text(
              _isArabic ? 'لدي حساب بالفعل' : 'I already have an account',
              style: AppTheme.bodyStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.oliveGreen,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegalFooter() {
    final baseStyle = AppTheme.bodyStyle(
      fontSize: 11,
      color: AppColors.textSecondary.withValues(alpha: 0.85),
      height: 1.4,
    );
    final linkStyle = baseStyle.copyWith(
      color: AppColors.primary,
      decoration: TextDecoration.underline,
      decorationColor: AppColors.gold,
      fontWeight: FontWeight.w700,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text.rich(
        TextSpan(
          style: baseStyle,
          children: _isArabic
              ? [
                  const TextSpan(
                    text: 'بالمتابعة لاستخدام سدر، فإنك توافق على ',
                  ),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.baseline,
                    baseline: TextBaseline.alphabetic,
                    child: GestureDetector(
                      onTap: _openLegalDocument,
                      child: Text(
                        'شروط الاستخدام وسياسة الخصوصية',
                        style: linkStyle,
                      ),
                    ),
                  ),
                  const TextSpan(text: '.'),
                ]
              : [
                  const TextSpan(text: 'By continuing, you agree to the '),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.baseline,
                    baseline: TextBaseline.alphabetic,
                    child: GestureDetector(
                      onTap: _openLegalDocument,
                      child: Text(
                        'Terms of Use and Privacy Policy',
                        style: linkStyle,
                      ),
                    ),
                  ),
                  const TextSpan(text: '.'),
                ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
