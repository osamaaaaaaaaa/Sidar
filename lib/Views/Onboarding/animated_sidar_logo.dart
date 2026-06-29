import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:skincare/Utils/AppColors.dart';

/// Luxury animated SIDAR logo medallion with slow orbital rings,
/// glowing celestial beads, and a gentle breathing floating motion.
class AnimatedSidarLogo extends StatefulWidget {
  final double size;

  const AnimatedSidarLogo({
    super.key,
    this.size = 145,
  });

  @override
  State<AnimatedSidarLogo> createState() => _AnimatedSidarLogoState();
}

class _AnimatedSidarLogoState extends State<AnimatedSidarLogo>
    with TickerProviderStateMixin {
  late final AnimationController _rotationController;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOutSine,
    );
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Widget _ring(double diameter, Color color, {double strokeWidth = 1.2}) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: strokeWidth),
      ),
    );
  }

  Widget _orbitDot(double offset, Color color, {double dotSize = 7}) {
    return Transform.translate(
      offset: Offset(offset, 0),
      child: Container(
        width: dotSize,
        height: dotSize,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.65),
              blurRadius: 7,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final baseSize = widget.size;
    final medallionSize = baseSize * 0.72;
    final outerRingSize = baseSize * 0.98;
    final innerRingSize = baseSize * 0.84;
    final logoSize = medallionSize * 0.68;

    return SizedBox(
      width: baseSize,
      height: baseSize,
      child: AnimatedBuilder(
        animation: Listenable.merge([_rotationController, _pulseAnimation]),
        builder: (context, child) {
          final pulseVal = _pulseAnimation.value;
          final floatOffset = math.sin(pulseVal * math.pi) * 4.0;
          final pulseScale = 1.0 + (pulseVal * 0.02);

          return Transform.translate(
            offset: Offset(0, -floatOffset),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Rotating orbital rings with glowing beads
                RotationTransition(
                  turns: _rotationController,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      _ring(
                        outerRingSize,
                        AppColors.gold.withValues(alpha: 0.28),
                        strokeWidth: 1.1,
                      ),
                      _ring(
                        innerRingSize,
                        AppColors.oliveGreen.withValues(alpha: 0.16),
                        strokeWidth: 1.0,
                      ),
                      _orbitDot(
                        outerRingSize / 2,
                        AppColors.gold,
                        dotSize: 6,
                      ),
                      _orbitDot(
                        -innerRingSize / 2,
                        AppColors.lightGold,
                        dotSize: 5,
                      ),
                      _orbitDot(
                        (innerRingSize / 2) * 0.7,
                        AppColors.oliveGreen.withValues(alpha: 0.7),
                        dotSize: 4,
                      ),
                    ],
                  ),
                ),

                // Radiant outer glow halo that pulses subtly
                Container(
                  width: medallionSize * 1.18,
                  height: medallionSize * 1.18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold
                            .withValues(alpha: 0.22 + (pulseVal * 0.08)),
                        blurRadius: 24 + (pulseVal * 6),
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: AppColors.oliveGreen.withValues(alpha: 0.12),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),

                // Central luxury white & gold medallion
                Transform.scale(
                  scale: pulseScale,
                  child: Container(
                    width: medallionSize,
                    height: medallionSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFFFFFF),
                          Color(0xFFF9F7F2),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.85),
                        width: 2.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.oliveGreen.withValues(alpha: 0.14),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                        BoxShadow(
                          color: AppColors.gold.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/sidar-emblem-clean.png',
                          width: logoSize,
                          height: logoSize,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              Image.asset(
                            'assets/images/WhatsApp Image 2026-03-02 at 3.31.37 AM.jpeg',
                            width: logoSize,
                            height: logoSize,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                              Icons.spa_rounded,
                              color: AppColors.oliveGreen,
                              size: 38,
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
      ),
    );
  }
}
