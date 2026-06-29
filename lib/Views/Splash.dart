import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:skincare/Services/auth_service.dart';
import 'package:skincare/Services/auth_profile_ui.dart';
import 'package:skincare/Services/app_config_service.dart';
import 'package:skincare/Views/Home/Home.dart';
import 'package:skincare/Views/Onboarding/welcome_landing_view.dart';
import 'package:skincare/Views/System/force_update_view.dart';
import 'package:skincare/Views/System/maintenance_mode_view.dart';
import 'package:skincare/Utils/AppColors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashGateView extends StatefulWidget {
  const SplashGateView({super.key});

  @override
  State<SplashGateView> createState() => _SplashGateViewState();
}

class _SplashGateViewState extends State<SplashGateView>
    with SingleTickerProviderStateMixin {
  final SupabaseClient _supabase = Supabase.instance.client;
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    AuthFlow.instance;
    _start();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    await AuthFlow.instance.ready;
    final start = DateTime.now();

    final session = _supabase.auth.currentSession;
    final user = _supabase.auth.currentUser;

    if (user != null && session != null && !AuthFlow.instance.recoveryPending) {
      try {
        await AuthService().prepareSession();
      } catch (_) {}
    }

    // Keep the splash animation visible for at least 1.8 seconds for an elegant experience
    final elapsed = DateTime.now().difference(start).inMilliseconds;
    final remaining = 1800 - elapsed;
    if (remaining > 0) {
      await Future.delayed(Duration(milliseconds: remaining));
    }

    if (!mounted) return;

    // Check system maintenance mode & mandatory app update
    try {
      final appStatus = await AppConfigService.instance.checkStatus();
      if (!mounted) return;

      if (appStatus.isMaintenance) {
        Get.offAll(
          () => MaintenanceModeView(config: appStatus.config),
          transition: Transition.fadeIn,
          duration: const Duration(milliseconds: 400),
        );
        return;
      }

      if (appStatus.isForceUpdate) {
        Get.offAll(
          () => ForceUpdateView(
            config: appStatus.config,
            currentVersion: appStatus.currentVersion,
          ),
          transition: Transition.fadeIn,
          duration: const Duration(milliseconds: 400),
        );
        return;
      }
    } catch (_) {
      // Gracefully continue on connection or config fetch error
    }

    if (AuthFlow.instance.recoveryPending && session != null) return;
    if (user != null && session != null && AuthService().isLoggedIn) {
      Get.offAll(
        () => const HomeView(),
        transition: Transition.fadeIn,
        duration: const Duration(milliseconds: 450),
      );
      return;
    }

    Get.offAll(
      () => const WelcomeLandingView(),
      transition: Transition.fadeIn,
      duration: const Duration(milliseconds: 450),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.0, -0.2),
            radius: 1.3,
            colors: [
              Color(0xFFF7F3EA),
              Color(0xFFFAF8F1),
            ],
            stops: [0.0, 0.9],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              final t = _animController.value;
              final pulse = 1.0 + (math.sin(t * 2 * math.pi) * 0.038);
              final ring1 = 1.0 + (t * 0.35);
              final ring1Opacity = (1.0 - t).clamp(0.0, 1.0) * 0.35;
              final ring2 = 1.0 + (((t + 0.5) % 1.0) * 0.35);
              final ring2Opacity = (1.0 - ((t + 0.5) % 1.0)).clamp(0.0, 1.0) * 0.30;

              return SizedBox(
                width: 220,
                height: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer expanding glow ring 1
                    Transform.scale(
                      scale: ring1,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.oliveGreen.withValues(alpha: ring1Opacity),
                            width: 2.0,
                          ),
                        ),
                      ),
                    ),

                    // Outer expanding glow ring 2
                    Transform.scale(
                      scale: ring2,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.gold.withValues(alpha: ring2Opacity),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),

                    // Center Animated Logo / Emblem
                    Transform.scale(
                      scale: pulse,
                      child: Container(
                        width: 136,
                        height: 136,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.70),
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.gold.withValues(alpha: 0.32),
                              blurRadius: 36,
                              offset: const Offset(0, 12),
                              spreadRadius: 2,
                            ),
                            BoxShadow(
                              color: AppColors.oliveGreen.withValues(alpha: 0.12),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child: Center(
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/sidar-emblem-clean.png',
                              width: 104,
                              height: 104,
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
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
