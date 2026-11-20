import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:skincare/Controllers/HomeController.dart';
import 'package:skincare/Services/app_feedback.dart';
import 'package:skincare/Services/purchase_policy.dart';
import 'package:skincare/Utils/AppColors.dart';
import 'package:skincare/Utils/AppTheme.dart';
import 'package:skincare/Views/History/DiagnosisHistory.dart';
import 'package:skincare/Views/Home/SidarChat.dart';
import 'package:skincare/Views/Home/scan.dart';
import 'package:skincare/Views/Settings/Settings.dart';
import 'package:skincare/Views/Subscrptions/Subscription.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView>
    with SingleTickerProviderStateMixin {
  late final HomeController controller;
  late final AnimationController _ringsAnimationController;

  @override
  void initState() {
    super.initState();
    _ringsAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    controller = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>()
        : Get.put(HomeController(), permanent: true);
    controller.loadHomeData();
  }

  @override
  void dispose() {
    _ringsAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      bottomNavigationBar: _bottomBar(),
      floatingActionButton: _chatButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Stack(
        children: [
          // Ambient luxury glow background
          Positioned.fill(
            child: Container(
              color: AppColors.background,
              child: Stack(
                children: [
                  Positioned(
                    top: -60,
                    right: -50,
                    child: Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.gold.withValues(alpha: 0.14),
                            AppColors.gold.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 300,
                    left: -70,
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.secondary.withValues(alpha: 0.09),
                            AppColors.secondary.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Scrollable Content
          SafeArea(
            bottom: false,
            child: Obx(
              () => RefreshIndicator(
                onRefresh: controller.refreshHome,
                color: AppColors.primary,
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 10,
                    bottom: 110,
                  ),
                  children: [
                    _topBar(),
                    const SizedBox(height: 12),
                    _environmentalRadarBanner(),
                    const SizedBox(height: 16),
                    _heroCard(),
                    const SizedBox(height: 24),
                    if (PurchasePolicy.subscriptionsEnabled) _eliteCard(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chatButton() {
    final isArabic = AppTheme.isArabic;
    return FloatingActionButton.extended(
      heroTag: 'sidar-chat',
      onPressed: () => Get.to(() => const SidarChatView()),
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 6,
      icon: const Icon(Icons.auto_awesome_rounded),
      label: Text(
        isArabic ? 'اسأل سدر' : 'Ask SIDAR',
        style: AppTheme.bodyStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    );
  }

  Widget _topBar() {
    final isAr = AppTheme.isArabic;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Website Brand Lockup Header Row: Emblem + SIDAR AI + BEAUTY INTELLIGENCE PLATFORM & My Account button
          Row(
            children: [
              // Logo + Brand Lockup
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.85),
                        width: 1.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gold.withValues(alpha: 0.22),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/sidar-emblem-clean.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.auto_awesome_rounded,
                              color: AppColors.gold,
                              size: 24,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'SIDAR',
                              style: TextStyle(
                                fontFamily: AppTheme.headingStyle().fontFamily,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.8,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'AI',
                              style: TextStyle(
                                fontFamily: AppTheme.headingStyle().fontFamily,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.8,
                                color: AppColors.gold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'BEAUTY INTELLIGENCE PLATFORM',
                        style: TextStyle(
                          fontFamily: AppTheme.monoFontFamily,
                          fontSize: 7.8,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                          color: AppColors.gold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              // Professional My Account Pill Button "حسابي"
              GestureDetector(
                onTap: () => Get.to(() => SettingsView()),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.45),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: AppColors.sageTint,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: AppColors.primary,
                          size: 15,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        isAr ? 'حسابي' : 'Account',
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
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Greeting & User Name under the brand bar
          Row(
            children: [
              Text(
                '${controller.greetingText}، ',
                style: AppTheme.bodyStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                controller.displayName,
                style: AppTheme.bodyStyle(
                  color: AppColors.primary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 4),
              const Text('✨', style: TextStyle(fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  /// AI Live Environmental & Climate Radar Floating Pills
  Widget _environmentalRadarBanner() {
    final isAr = AppTheme.isArabic;
    return Obx(() {
      final climate = controller.climateData.value;
      final isLoading = controller.isClimateLoading.value;

      if (climate == null) {
        return Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(21),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.35),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 13,
                height: 13,
                child: CircularProgressIndicator(
                  strokeWidth: 1.8,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isAr
                    ? 'جاري الاتصال بالأقمار الصناعية للرادار الحي...'
                    : 'Reading live satellite radar...',
                style: TextStyle(
                  fontFamily: AppTheme.appFontFamily,
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Horizontal Floating Pills Carousel
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              clipBehavior: Clip.none,
              children: [
                // Pill 1: Location & Live Temperature
                _floatingPill(
                  prefixText: climate.flag,
                  label: '${climate.country} ${climate.temperature.round()}°C',
                  sub: climate.conditionText,
                  color: AppColors.primary,
                  isLive: climate.isLive,
                  icon: climate.conditionIcon,
                ),
                const SizedBox(width: 8),
                // Pill 2: UV Index
                _floatingPill(
                  icon: Icons.wb_sunny_rounded,
                  label: 'UV ${climate.uvIndex.toStringAsFixed(1)}',
                  sub: climate.uvStatus,
                  color: climate.uvColor,
                ),
                const SizedBox(width: 8),
                // Pill 3: Air Quality (AQI)
                _floatingPill(
                  icon: Icons.air_rounded,
                  label: '${climate.aqi} AQI',
                  sub: climate.aqiStatus,
                  color: climate.aqiColor,
                ),
                const SizedBox(width: 8),
                // Pill 4: Humidity
                _floatingPill(
                  icon: Icons.water_drop_rounded,
                  label: '${climate.humidity}%',
                  sub: climate.humidityStatus,
                  color: climate.humidityColor,
                ),
                const SizedBox(width: 8),
                // Pill 5: Interactive Sync / Refresh
                _floatingRefreshPill(isLoading, isAr),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Floating Minimalist AI Skin Prescription Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.35),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  size: 13,
                  color: AppColors.gold,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    climate.aiSkinAdvice,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTheme.appFontFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _floatingPill({
    IconData? icon,
    String? prefixText,
    required String label,
    required String sub,
    required Color color,
    bool isLive = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.32),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLive) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: const Color(0xFF2ECC71),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2ECC71).withValues(alpha: 0.8),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
          ],
          if (prefixText != null) ...[
            Text(prefixText, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 5),
          ],
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.headingStyle().fontFamily,
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              sub,
              style: TextStyle(
                fontFamily: AppTheme.appFontFamily,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _floatingRefreshPill(bool isLoading, bool isAr) {
    return GestureDetector(
      onTap: isLoading
          ? null
          : () {
              controller.fetchClimateRadar(forceRefresh: true);
              AppFeedback.success(
                isAr
                    ? 'تم تحديث بيانات الطقس والأشعة الآن.'
                    : 'Live weather and UV data have been updated.',
                title: isAr ? 'رادار الطقس الحي' : 'Live Climate Radar',
              );
            },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.sageTint.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.35),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            isLoading
                ? const SizedBox(
                    width: 11,
                    height: 11,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.6,
                      color: AppColors.gold,
                    ),
                  )
                : const Icon(
                    Icons.sync_rounded,
                    size: 13,
                    color: AppColors.gold,
                  ),
            const SizedBox(width: 4),
            Text(
              isAr ? 'تحديث حي' : 'Live Sync',
              style: TextStyle(
                fontFamily: AppTheme.appFontFamily,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroCard() {
    final isAr = AppTheme.isArabic;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.35),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.07),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titles
          Text(
            'smart_skin_analysis_title'.tr,
            style: AppTheme.headingStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'smart_skin_analysis_desc'.tr,
            style: AppTheme.bodyStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          // Rotating central emblem graphic
          Center(child: _heroRings()),
          const SizedBox(height: 20),

          // Tangible AI Live Diagnostic Status Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  AppColors.sageTint.withValues(alpha: 0.55),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.35),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF2ECC71),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isAr ? 'جاهز للفحص الفوري' : 'Ready to Scan',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.auto_awesome_rounded,
                      size: 16,
                      color: AppColors.gold,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'hero_insight_text'.tr,
                  style: AppTheme.bodyStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),

                // Prominent CTA Button: Start Free Analysis (Moved up inside hero card)
                GestureDetector(
                  onTap: () => Get.to(() => ScanView()),
                  child: Container(
                    height: 52,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFC8A66A),
                          Color(0xFFD9BF8A),
                          Color(0xFFB89454),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gold.withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.black87,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isAr ? 'ابدأ التحليل المجاني' : 'Start Free Analysis',
                          style: TextStyle(
                            fontFamily: AppTheme.appFontFamily,
                            color: Colors.black87,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          isAr
                              ? Icons.arrow_back_rounded
                              : Icons.arrow_forward_rounded,
                          color: Colors.black87,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 3 Rich Stat Cards
          Row(
            children: [
              Expanded(
                child: _richStatCard(
                  icon: Icons.privacy_tip_outlined,
                  title: 'hero_stat_privacy_title'.tr,
                  value: 'hero_stat_privacy_value'.tr,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _richStatCard(
                  icon: Icons.bolt_rounded,
                  title: 'hero_stat_speed_title'.tr,
                  value: isAr ? 'ثوانٍ' : 'Seconds',
                  color: const Color(0xFFE67E22),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _richStatCard(
                  icon: Icons.health_and_safety_rounded,
                  title: 'hero_stat_followup_title'.tr,
                  value: '24/7',
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _richStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            const Color(0xFFFAF8F3),
            AppColors.sageTint.withValues(alpha: 0.35),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.40),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Circular elevated icon capsule with glowing aura
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.12),
              border: Border.all(
                color: color.withValues(alpha: 0.35),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.14),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 10),
          // Bold High-Contrast Value
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.headingStyle().fontFamily,
              fontSize: 16.5,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          // Subtitle / Label
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppTheme.appFontFamily,
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          // Delicate Bottom Color Bar
          Container(
            width: 22,
            height: 2.5,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroRings() {
    return AnimatedBuilder(
      animation: _ringsAnimationController,
      builder: (context, _) {
        final t = _ringsAnimationController.value;
        final pulse = 1.0 + (math.sin(t * 2 * math.pi) * 0.024);
        final glowAlpha = 0.20 + (math.sin(t * 2 * math.pi) * 0.08);

        return SizedBox(
          width: 250,
          height: 250,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Ambient breathing gold halo behind the logo
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: glowAlpha),
                      blurRadius: 34,
                      spreadRadius: 6,
                    ),
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      blurRadius: 24,
                    ),
                  ],
                ),
              ),

              // Orbiting elements (rings, particles, bubbles) rotating continuously
              RotationTransition(
                turns: _ringsAnimationController,
                child: SizedBox(
                  width: 250,
                  height: 250,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      _ring(232, color: AppColors.gold.withValues(alpha: 0.25)),
                      _ring(
                        188,
                        color: AppColors.primary.withValues(alpha: 0.26),
                      ),
                      _ring(144, color: AppColors.gold.withValues(alpha: 0.40)),

                      // Twinkling orbit dots along the tracks
                      Positioned(
                        top: 26,
                        left: 56,
                        child: _orbitDot(AppColors.gold, size: 6),
                      ),
                      Positioned(
                        bottom: 30,
                        right: 68,
                        child: _orbitDot(AppColors.secondary, size: 5),
                      ),
                      Positioned(
                        top: 110,
                        right: 8,
                        child: _orbitDot(AppColors.gold, size: 4),
                      ),

                      // Orbiting action bubbles with upright icons
                      Positioned(
                        right: 22,
                        top: 40,
                        child: _miniBubble(
                          Icons.auto_awesome_rounded,
                          color: AppColors.gold,
                        ),
                      ),
                      Positioned(
                        left: 24,
                        bottom: 42,
                        child: _miniBubble(
                          Icons.shield_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                      Positioned(
                        right: 26,
                        bottom: 36,
                        child: _miniBubble(
                          Icons.bolt_rounded,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Center Logo Emblem with subtle breathing pulse
              Transform.scale(
                scale: pulse,
                child: Container(
                  width: 118,
                  height: 118,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFFFFF), Color(0xFFF7F4EA)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: AppColors.gold, width: 2.4),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.22),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/sidar-emblem-clean.png',
                        width: 90,
                        height: 90,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Image.asset(
                          'assets/images/WhatsApp Image 2026-03-02 at 3.31.37 AM.jpeg',
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.auto_awesome_rounded,
                                color: AppColors.gold,
                                size: 46,
                              ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _orbitDot(Color color, {double size = 6}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.65),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }

  Widget _ring(double size, {Color? color}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: color ?? AppColors.primary.withValues(alpha: 0.2),
          width: 1.2,
        ),
      ),
    );
  }

  Widget _miniBubble(IconData icon, {Color? color}) {
    return RotationTransition(
      turns: ReverseAnimation(_ringsAnimationController),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.50),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.10),
              blurRadius: 6,
            ),
          ],
        ),
        child: Icon(icon, color: color ?? AppColors.primary, size: 20),
      ),
    );
  }

  Widget _sectionHeader({required String title, required String subtitle}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 4,
          height: 24,
          margin: const EdgeInsets.only(bottom: 4, left: 8, right: 8),
          decoration: BoxDecoration(
            color: AppColors.gold,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.headingStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppTheme.bodyStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'more'.tr,
              style: AppTheme.headingStyle(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 12,
              color: AppColors.primary,
            ),
          ],
        ),
      ],
    );
  }

  Widget _doctorsCards() {
    if (controller.isDoctorsLoading.value) {
      return SizedBox(
        height: 220,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          separatorBuilder: (context, index) => const SizedBox(width: 12),
          itemBuilder: (context, index) =>
              const _ShimmerBox(width: 175, height: 220, borderRadius: 22),
        ),
      );
    }
    if (controller.doctors.isEmpty) {
      return _emptyCard('No doctors found');
    }

    return SizedBox(
      height: 226,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: controller.doctors.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final doc = controller.doctors[index];
          final profile = (doc['profiles'] is List)
              ? ((doc['profiles'] as List).isNotEmpty
                    ? (doc['profiles'] as List).first as Map<String, dynamic>
                    : <String, dynamic>{})
              : (doc['profiles'] as Map<String, dynamic>? ??
                    <String, dynamic>{});
          final avatar = (profile['avatar_url'] ?? '').toString();
          final name = (profile['full_name'] ?? 'Doctor').toString();
          final spec = (doc['specialization'] ?? '').toString();
          final rating = (doc['rating'] ?? '').toString();

          return Container(
            width: 180,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.32),
                width: 1.1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.60),
                          width: 1.8,
                        ),
                      ),
                      child: ClipOval(
                        child: avatar.isEmpty
                            ? Container(
                                width: 76,
                                height: 76,
                                decoration: const BoxDecoration(
                                  color: AppColors.sageTint,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.person_rounded,
                                  color: AppColors.primary,
                                  size: 40,
                                ),
                              )
                            : Image.network(
                                avatar,
                                width: 76,
                                height: 76,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return const _ShimmerBox(
                                    width: 76,
                                    height: 76,
                                    borderRadius: 100,
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      width: 76,
                                      height: 76,
                                      decoration: const BoxDecoration(
                                        color: AppColors.sageTint,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.person_rounded,
                                        color: AppColors.primary,
                                        size: 40,
                                      ),
                                    ),
                              ),
                      ),
                    ),
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified_rounded,
                          color: AppColors.gold,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodyStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  spec,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodyStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: AppColors.gold,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        rating,
                        style: AppTheme.headingStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _eliteCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F5F4D), Color(0xFF178568), Color(0xFF0A3026)],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.60),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.30),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.20),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.70)),
              color: Colors.black.withValues(alpha: 0.25),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  size: 14,
                  color: AppColors.gold,
                ),
                const SizedBox(width: 6),
                Text(
                  'SIDAR ELITE',
                  style: AppTheme.headingStyle(
                    color: AppColors.gold,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'elite_membership_title'.tr,
            style: AppTheme.headingStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'elite_membership_desc'.tr,
            style: AppTheme.bodyStyle(
              color: const Color(0xFFE0EAE5),
              fontSize: 14,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          if (PurchasePolicy.subscriptionCheckoutEnabled)
            AppTheme.goldButton(
              text: 'join_now'.tr,
              width: 150,
              onPressed: () => Get.to(() => const SubscriptionView()),
            ),
        ],
      ),
    );
  }

  Widget _bottomBar() {
    final isAr = AppTheme.isArabic;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: 1,
          ),
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.10),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(
            icon: Icons.home_rounded,
            label: isAr ? 'الرئيسية' : 'Home',
            isSelected: true,
            onTap: () {},
          ),
          _navItem(
            icon: Icons.receipt_long_rounded,
            label: isAr ? 'الفحوصات' : 'History',
            isSelected: false,
            onTap: () => Get.to(() => DiagnosisHistoryView()),
          ),
          _scanCenterButton(),
          if (PurchasePolicy.subscriptionsEnabled)
            _navItem(
              icon: Icons.workspace_premium_rounded,
              label: isAr ? 'العضويات' : 'Memberships',
              isSelected: false,
              onTap: () => Get.to(() => const SubscriptionView()),
            ),
          _navItem(
            icon: Icons.person_rounded,
            label: isAr ? 'حسابي' : 'Profile',
            isSelected: false,
            onTap: () => Get.to(() => SettingsView()),
          ),
        ],
      ),
    );
  }

  Widget _scanCenterButton() {
    return GestureDetector(
      onTap: () => Get.to(() => ScanView()),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF178568), Color(0xFF0F5F4D), Color(0xFF0A3026)],
          ),
          border: Border.all(color: AppColors.gold, width: 2.2),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 4),
              spreadRadius: 1,
            ),
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.30),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(
          Icons.document_scanner_rounded,
          color: AppColors.gold,
          size: 26,
        ),
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(6),
              decoration: isSelected
                  ? BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    )
                  : null,
              child: Icon(
                icon,
                size: 24,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textSecondary.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTheme.bodyStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textSecondary.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyCard(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Text(
        text,
        style: AppTheme.bodyStyle(color: AppColors.textSecondary),
      ),
    );
  }
}

class _ShimmerBox extends StatefulWidget {
  const _ShimmerBox({
    required this.width,
    required this.height,
    this.borderRadius = 12,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + (t * 2), -0.3),
              end: Alignment(1.0 + (t * 2), 0.3),
              colors: [
                AppColors.surface.withValues(alpha: 0.55),
                AppColors.borderSoft.withValues(alpha: 0.45),
                AppColors.surface.withValues(alpha: 0.55),
              ],
            ),
          ),
        );
      },
    );
  }
}
