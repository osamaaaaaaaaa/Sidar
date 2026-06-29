import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 3D-styled smiling sphere mascot matching the user's reference video.
class SmilingMascot extends StatefulWidget {
  final double size;
  final bool animated;

  const SmilingMascot({
    super.key,
    this.size = 120,
    this.animated = true,
  });

  @override
  State<SmilingMascot> createState() => _SmilingMascotState();
}

class _SmilingMascotState extends State<SmilingMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    if (widget.animated) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animated) {
      return _buildSphere(0.0);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final val = _controller.value;
        final floatOffset = math.sin(val * math.pi) * 5.0;
        final pulseScale = 1.0 + (math.sin(val * math.pi) * 0.025);

        return Transform.translate(
          offset: Offset(0, -floatOffset),
          child: Transform.scale(
            scale: pulseScale,
            child: _buildSphere(val),
          ),
        );
      },
    );
  }

  Widget _buildSphere(double animVal) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.25, -0.35),
          radius: 0.95,
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFF9F7F2),
            Color(0xFFEBE6DC),
          ],
          stops: [0.0, 0.65, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F5F4D).withValues(alpha: 0.09),
            blurRadius: widget.size * 0.22,
            offset: Offset(0, widget.size * 0.10),
            spreadRadius: 1,
          ),
          BoxShadow(
            color: const Color(0xFFC8A66A).withValues(alpha: 0.12),
            blurRadius: widget.size * 0.15,
            offset: Offset(0, widget.size * 0.04),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _MascotFacePainter(size: widget.size, animVal: animVal),
      ),
    );
  }
}

class _MascotFacePainter extends CustomPainter {
  final double size;
  final double animVal;

  _MascotFacePainter({required this.size, required this.animVal});

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final cx = canvasSize.width / 2;
    final cy = canvasSize.height / 2;
    final scale = size / 120.0;

    final paintStroke = Paint()
      ..color = const Color(0xFF1E2824)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2.4 * scale, 1.8)
      ..strokeCap = StrokeCap.round;

    // Smiling eyes (curved upward arcs: ⌒  ⌒)
    final eyeSpacing = 16.0 * scale;
    final eyeWidth = 10.0 * scale;
    final eyeY = cy - (4.0 * scale);
    final eyeArcHeight = 5.0 * scale;

    // Left eye
    final leftEyePath = Path()
      ..moveTo(cx - eyeSpacing - eyeWidth, eyeY + eyeArcHeight * 0.3)
      ..quadraticBezierTo(
        cx - eyeSpacing - eyeWidth / 2,
        eyeY - eyeArcHeight,
        cx - eyeSpacing,
        eyeY + eyeArcHeight * 0.3,
      );
    canvas.drawPath(leftEyePath, paintStroke);

    // Right eye
    final rightEyePath = Path()
      ..moveTo(cx + eyeSpacing, eyeY + eyeArcHeight * 0.3)
      ..quadraticBezierTo(
        cx + eyeSpacing + eyeWidth / 2,
        eyeY - eyeArcHeight,
        cx + eyeSpacing + eyeWidth,
        eyeY + eyeArcHeight * 0.3,
      );
    canvas.drawPath(rightEyePath, paintStroke);

    // Smiling mouth (gentle curved smile: ‿)
    final mouthY = cy + (10.0 * scale);
    final mouthWidth = 15.0 * scale;
    final mouthDepth = 8.0 * scale + (animVal * 1.5 * scale);

    final mouthPath = Path()
      ..moveTo(cx - mouthWidth, mouthY)
      ..quadraticBezierTo(
        cx,
        mouthY + mouthDepth,
        cx + mouthWidth,
        mouthY,
      );
    canvas.drawPath(mouthPath, paintStroke);

    // Subtle soft rosy cheeks (blush)
    final blushPaint = Paint()
      ..color = const Color(0xFFFFB6B6).withValues(alpha: 0.28)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(cx - eyeSpacing - eyeWidth * 0.5, eyeY + 12.0 * scale),
      5.0 * scale,
      blushPaint,
    );
    canvas.drawCircle(
      Offset(cx + eyeSpacing + eyeWidth * 0.5, eyeY + 12.0 * scale),
      5.0 * scale,
      blushPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MascotFacePainter oldDelegate) =>
      oldDelegate.animVal != animVal || oldDelegate.size != size;
}
