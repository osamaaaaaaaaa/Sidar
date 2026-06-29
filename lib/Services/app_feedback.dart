import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:skincare/Utils/AppColors.dart';
import 'package:skincare/Utils/AppTheme.dart';

enum FeedbackKind { success, error, warning, info }

/// A single, animated in-app feedback surface that replaces transient snackbars.
class AppFeedback {
  AppFeedback._();

  static OverlayEntry? _activeEntry;

  static void success(String message, {String? title}) =>
      show(message: message, title: title, kind: FeedbackKind.success);

  static void error(String message, {String? title}) => show(
    message: message,
    title: title,
    kind: FeedbackKind.error,
    duration: const Duration(seconds: 5),
  );

  static void warning(String message, {String? title}) =>
      show(message: message, title: title, kind: FeedbackKind.warning);

  static void info(String message, {String? title}) =>
      show(message: message, title: title, kind: FeedbackKind.info);

  static void show({
    required String message,
    FeedbackKind kind = FeedbackKind.info,
    String? title,
    Duration duration = const Duration(seconds: 4),
  }) {
    if (message.trim().isEmpty) return;

    // Get.overlayContext can itself be the Overlay's _Theater context. Calling
    // Overlay.of from that context looks for an ancestor and throws, even
    // though a root navigator exists. Prefer the navigator-owned Overlay and
    // use maybeOf only as a safe fallback during app startup.
    final navigatorOverlay = Get.key.currentState?.overlay;
    final context = Get.context;
    final overlay =
        navigatorOverlay ??
        (context == null ? null : Overlay.maybeOf(context, rootOverlay: true));
    if (overlay == null) return;

    _activeEntry?.remove();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _AnimatedFeedbackCard(
        title: title,
        message: message.trim(),
        kind: kind,
        duration: duration,
        onDismissed: () {
          if (identical(_activeEntry, entry)) _activeEntry = null;
          entry.remove();
        },
      ),
    );
    _activeEntry = entry;
    overlay.insert(entry);
  }
}

class _AnimatedFeedbackCard extends StatefulWidget {
  const _AnimatedFeedbackCard({
    required this.message,
    required this.kind,
    required this.duration,
    required this.onDismissed,
    this.title,
  });

  final String message;
  final String? title;
  final FeedbackKind kind;
  final Duration duration;
  final VoidCallback onDismissed;

  @override
  State<_AnimatedFeedbackCard> createState() => _AnimatedFeedbackCardState();
}

class _AnimatedFeedbackCardState extends State<_AnimatedFeedbackCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _dismissTimer;
  var _isClosing = false;

  Color get _color => switch (widget.kind) {
    FeedbackKind.success => AppColors.secondary,
    FeedbackKind.error => AppColors.error,
    FeedbackKind.warning => AppColors.gold,
    FeedbackKind.info => AppColors.primary,
  };

  IconData get _icon => switch (widget.kind) {
    FeedbackKind.success => Icons.check_circle_rounded,
    FeedbackKind.error => Icons.error_rounded,
    FeedbackKind.warning => Icons.warning_amber_rounded,
    FeedbackKind.info => Icons.auto_awesome_rounded,
  };

  String get _fallbackTitle {
    final isArabic = AppTheme.isArabic;
    return switch (widget.kind) {
      FeedbackKind.success => isArabic ? 'تم بنجاح' : 'Success',
      FeedbackKind.error =>
        isArabic ? 'تعذر إكمال العملية' : 'Unable to complete',
      FeedbackKind.warning => isArabic ? 'تنبيه' : 'Notice',
      FeedbackKind.info => isArabic ? 'سِدر' : 'SIDAR',
    };
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      reverseDuration: const Duration(milliseconds: 220),
    )..forward();
    _dismissTimer = Timer(widget.duration, _dismiss);
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    if (_isClosing) return;
    _isClosing = true;
    await _controller.reverse();
    widget.onDismissed();
  }

  @override
  Widget build(BuildContext context) {
    final slide = Tween<Offset>(
      begin: const Offset(0, -0.28),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 12,
      left: 16,
      right: 16,
      child: SafeArea(
        bottom: false,
        child: SlideTransition(
          position: slide,
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: _controller,
              curve: Curves.easeOut,
            ),
            child: GestureDetector(
              onTap: _dismiss,
              onVerticalDragEnd: (_) => _dismiss(),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _color.withValues(alpha: 0.48)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.18),
                        blurRadius: 26,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: _color.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_icon, color: _color, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title?.trim().isNotEmpty == true
                                  ? widget.title!.trim()
                                  : _fallbackTitle,
                              style: AppTheme.headingStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: _color,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.message,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.bodyStyle(
                                fontSize: 13,
                                color: AppColors.textPrimary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _dismiss,
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          Icons.close_rounded,
                          color: AppColors.textSecondary.withValues(alpha: 0.7),
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
