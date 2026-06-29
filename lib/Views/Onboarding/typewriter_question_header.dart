import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:skincare/Utils/AppColors.dart';
import 'package:skincare/Utils/AppTheme.dart';

/// Typewriter question header with animated pencil avatar matching the reference video.
class TypewriterQuestionHeader extends StatefulWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onTypingComplete;

  const TypewriterQuestionHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.onTypingComplete,
  });

  @override
  State<TypewriterQuestionHeader> createState() =>
      _TypewriterQuestionHeaderState();
}

class _TypewriterQuestionHeaderState extends State<TypewriterQuestionHeader>
    with SingleTickerProviderStateMixin {
  String _displayedTitle = '';
  String _displayedSubtitle = '';
  bool _isTyping = true;
  Timer? _typingTimer;

  late final AnimationController _pencilAnimController;

  @override
  void initState() {
    super.initState();
    _pencilAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _startTyping();
  }

  @override
  void didUpdateWidget(covariant TypewriterQuestionHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.title != widget.title ||
        oldWidget.subtitle != widget.subtitle) {
      _startTyping();
    }
  }

  void _startTyping() {
    _typingTimer?.cancel();
    setState(() {
      _displayedTitle = '';
      _displayedSubtitle = '';
      _isTyping = true;
    });

    final titleRunes = widget.title.runes.toList();
    final subtitleRunes = widget.subtitle.runes.toList();

    int titleIdx = 0;
    int subIdx = 0;

    // Fast, natural typewriter speed (~22ms per char for smooth typing)
    _typingTimer = Timer.periodic(const Duration(milliseconds: 22), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (titleIdx < titleRunes.length) {
        titleIdx++;
        setState(() {
          _displayedTitle = String.fromCharCodes(
            titleRunes.sublist(0, titleIdx),
          );
        });
      } else if (subIdx < subtitleRunes.length) {
        subIdx++;
        setState(() {
          _displayedSubtitle = String.fromCharCodes(
            subtitleRunes.sublist(0, subIdx),
          );
        });
      } else {
        timer.cancel();
        setState(() => _isTyping = false);
        widget.onTypingComplete?.call();
      }
    });
  }

  void _skipTyping() {
    _typingTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _displayedTitle = widget.title;
      _displayedSubtitle = widget.subtitle;
      _isTyping = false;
    });
    widget.onTypingComplete?.call();
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _pencilAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _skipTyping,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Speech Bubble Card with typing text
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppColors.oliveGreen.withValues(alpha: 0.18),
                  width: 1.1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    _displayedTitle,
                    style: AppTheme.headingStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),

                  if (_displayedSubtitle.isNotEmpty || !_isTyping) ...[
                    const SizedBox(height: 6),
                    Text(
                      _displayedSubtitle,
                      style: AppTheme.bodyStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPencilAvatar() {
    return AnimatedBuilder(
      animation: _pencilAnimController,
      builder: (context, child) {
        final val = _pencilAnimController.value;
        final wobbleAngle = _isTyping
            ? (math.sin(val * math.pi * 2) * 0.12)
            : 0.0;
        final bobbingY = _isTyping ? (math.sin(val * math.pi * 2) * 2.0) : 0.0;

        return Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              center: Alignment(-0.25, -0.35),
              radius: 0.95,
              colors: [Color(0xFFFFFFFF), Color(0xFFF9F7F2), Color(0xFFEBE6DC)],
              stops: [0.0, 0.65, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F5F4D).withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: AppColors.oliveGreen.withValues(alpha: 0.15),
              width: 1.0,
            ),
          ),
          child: Center(
            child: Transform.translate(
              offset: Offset(0, bobbingY),
              child: Transform.rotate(
                angle: wobbleAngle,
                child: CustomPaint(
                  size: const Size(28, 28),
                  painter: _PencilScribblePainter(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Custom painter for the slanted pencil + wavy ink scribble (~ ✏️)
class _PencilScribblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = const Color(0xFF1E2824)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = const Color(0xFF1E2824)
      ..style = PaintingStyle.fill;

    // Wavy line at the bottom-left representing written ink stroke: ~
    final wavePath = Path()
      ..moveTo(size.width * 0.10, size.height * 0.78)
      ..quadraticBezierTo(
        size.width * 0.22,
        size.height * 0.68,
        size.width * 0.34,
        size.height * 0.78,
      )
      ..quadraticBezierTo(
        size.width * 0.44,
        size.height * 0.86,
        size.width * 0.54,
        size.height * 0.78,
      );
    canvas.drawPath(wavePath, strokePaint);

    // Slanted Pencil Body pointing down-left towards (0.50, 0.76)
    // Pencil tip: (size.width * 0.48, size.height * 0.72)
    // Pencil eraser end: (size.width * 0.82, size.height * 0.22)
    final tip = Offset(size.width * 0.48, size.height * 0.70);
    final top = Offset(size.width * 0.82, size.height * 0.20);

    // Draw main pencil shaft line
    canvas.drawLine(tip, top, strokePaint..strokeWidth = 3.2);

    // Draw pencil tip triangle / nib
    final tipPath = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(tip.dx + 4.0, tip.dy - 1.0)
      ..lineTo(tip.dx + 1.0, tip.dy - 4.0)
      ..close();
    canvas.drawPath(tipPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
