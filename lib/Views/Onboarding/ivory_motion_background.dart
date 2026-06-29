import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:skincare/Utils/AppColors.dart';

/// Ivory motion background matching the official SIDAR web client aesthetic:
/// Soft cream / ivory base with gentle floating ambient glow orbs.
class IvoryMotionBackground extends StatefulWidget {
  final Widget child;

  const IvoryMotionBackground({super.key, required this.child});

  @override
  State<IvoryMotionBackground> createState() => _IvoryMotionBackgroundState();
}

class _IvoryMotionBackgroundState extends State<IvoryMotionBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, _) {
          final t = _animController.value * 2 * math.pi;
          final orb1X = math.sin(t) * 25.0;
          final orb1Y = math.cos(t) * 35.0;
          final orb2X = math.cos(t * 0.8) * 30.0;
          final orb2Y = math.sin(t * 0.8) * 25.0;
          final pulse = 1.0 + math.sin(t) * 0.05;

          return Stack(
            children: [
              // Radial base glow
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0.0, -0.3),
                      radius: 1.4,
                      colors: [
                        Color(0xFFF7F3EA),
                        Color(0xFFFAF8F1),
                      ],
                      stops: [0.0, 0.85],
                    ),
                  ),
                ),
              ),

              // Floating Ambient Orb 1 (Soft Gold/Ivory warmth top-right)
              Positioned(
                top: -60 + orb1Y,
                right: -50 + orb1X,
                child: Transform.scale(
                  scale: pulse,
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.gold.withValues(alpha: 0.16),
                          AppColors.gold.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Floating Ambient Orb 2 (Soft Sage/Mint tint bottom-left)
              Positioned(
                bottom: 80 + orb2Y,
                left: -70 + orb2X,
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.secondary.withValues(alpha: 0.10),
                        AppColors.secondary.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),

              // Floating Ambient Orb 3 (Soft Center Glow)
              Positioned(
                top: 240 - orb1Y * 0.5,
                left: 60 - orb2X * 0.5,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFE6EFEA).withValues(alpha: 0.35),
                        const Color(0xFFFAF8F1).withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),

              // Content
              SafeArea(child: widget.child),
            ],
          );
        },
      ),
    );
  }
}
