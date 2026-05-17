import 'dart:ui';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// showToasti — call this from anywhere to display the toast from the top
// ---------------------------------------------------------------------------

OverlayEntry? _activeToastEntry;

void showToasti(
  BuildContext context, {
  required String title,
  required String description,
  required ToastType type,
  required Duration duration,
  double topOffset = 56,
  double horizontalMargin = 16,
  // Customization properties
  TextStyle? titleStyle,
  TextStyle? descriptionStyle,
  Color? backgroundColor,
  double? height,
  double? width,
  bool enableAnimation = true, // <--- New flag to toggle animations
}) {
  // Dismiss any currently visible toast immediately
  _activeToastEntry?.remove();
  _activeToastEntry = null;

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _ToastOverlay(
      title: title,
      description: description,
      type: type,
      topOffset: topOffset,
      horizontalMargin: horizontalMargin,
      duration: duration,
      titleStyle: titleStyle,
      descriptionStyle: descriptionStyle,
      backgroundColor: backgroundColor,
      height: height,
      maxWidth: width,
      enableAnimation: enableAnimation, // Pass it down
      onDismissed: () {
        entry.remove();
        if (_activeToastEntry == entry) _activeToastEntry = null;
      },
    ),
  );

  _activeToastEntry = entry;
  Overlay.of(context).insert(entry);
}

// ---------------------------------------------------------------------------
// Overlay host — owns the enter/exit animation
// ---------------------------------------------------------------------------

class _ToastOverlay extends StatefulWidget {
  final String title;
  final String description;
  final ToastType type;
  final double topOffset;
  final double horizontalMargin;
  final Duration duration;
  final VoidCallback onDismissed;

  final TextStyle? titleStyle;
  final TextStyle? descriptionStyle;
  final Color? backgroundColor;
  final double? height;
  final double? maxWidth;
  final bool enableAnimation;

  const _ToastOverlay({
    required this.title,
    required this.description,
    required this.type,
    required this.topOffset,
    required this.horizontalMargin,
    required this.duration,
    required this.onDismissed,
    this.titleStyle,
    this.descriptionStyle,
    this.backgroundColor,
    this.height,
    this.maxWidth,
    this.enableAnimation = true,
  });

  @override
  State<_ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<_ToastOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    // If animations are disabled, use a duration of zero for instant appearance
    final animDuration = widget.enableAnimation
        ? const Duration(milliseconds: 480)
        : Duration.zero;

    final reverseAnimDuration = widget.enableAnimation
        ? const Duration(milliseconds: 340)
        : Duration.zero;

    _controller = AnimationController(
      vsync: this,
      duration: animDuration,
      reverseDuration: reverseAnimDuration,
    );

    // Slides in from above the screen
    _slide = Tween<Offset>(
      begin: const Offset(0, -1.6),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _scale = Tween<double>(
      begin: 0.88,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();

    // Auto-dismiss after [duration]
    Future.delayed(widget.duration, _dismiss);
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    await _controller.reverse();
    widget.onDismissed();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final screenW = mq.size.width;
    final maxW =
        widget.maxWidth ??
        (screenW - widget.horizontalMargin * 2).clamp(0.0, 343.0);

    return Positioned(
      top: widget.topOffset + mq.padding.top,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, child) => SlideTransition(
          position: _slide,
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(scale: _scale, child: child),
          ),
        ),
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onVerticalDragEnd: (details) {
                // Swipe up to dismiss
                if (details.primaryVelocity != null &&
                    details.primaryVelocity! < -200) {
                  _dismiss();
                }
              },
              child: Toasti(
                title: widget.title,
                description: widget.description,
                type: widget.type,
                horizontalMargin: widget.horizontalMargin,
                maxWidth: maxW,
                titleStyle: widget.titleStyle,
                descriptionStyle: widget.descriptionStyle,
                backgroundColor: widget.backgroundColor,
                height: widget.height,
                enableAnimation: widget.enableAnimation, // Pass it down
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Toasti — the visual widget
// ---------------------------------------------------------------------------

class Toasti extends StatelessWidget {
  final String title;
  final String description;
  final ToastType type;
  final double horizontalMargin;

  /// Customization API properties
  final double? maxWidth;
  final TextStyle? titleStyle;
  final TextStyle? descriptionStyle;
  final Color? backgroundColor;
  final double? height;
  final bool enableAnimation;

  const Toasti({
    super.key,
    required this.title,
    required this.description,
    required this.type,
    this.horizontalMargin = 16,
    this.maxWidth,
    this.titleStyle,
    this.descriptionStyle,
    this.backgroundColor,
    this.height,
    this.enableAnimation = true,
  });

  Color _accentColor(ToastType t) {
    switch (t) {
      case ToastType.success:
        return const Color(0xFF06A867);
      case ToastType.warning:
        return const Color(0xFFF59E0B);
      case ToastType.error:
        return Colors.redAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor(type);
    final screenW = MediaQuery.sizeOf(context).width;
    final maxW = maxWidth ?? (screenW - horizontalMargin * 2).clamp(0.0, 343.0);

    final scale = (maxW / 343.0).clamp(0.6, 1.0);
    final containerHeight = height ?? 82.0 * scale;

    final defaultTitleStyle = TextStyle(
      fontSize: 17.0 * scale,
      fontWeight: FontWeight.w600,
      color: Colors.white,
      letterSpacing: -0.4,
    );

    final defaultDescStyle = TextStyle(
      fontSize: 13.0 * scale,
      color: Colors.white.withOpacity(0.7),
      fontWeight: FontWeight.w400,
      letterSpacing: -0.1,
    );

    final iconArea = 40.0 * scale;
    final iconCircle = 24.0 * scale;
    final hPad = 16.0 * scale;
    final gap = 12.0 * scale;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxW),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            height: containerHeight,
            padding: EdgeInsets.symmetric(horizontal: hPad),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 0.5,
              ),
              gradient: backgroundColor == null
                  ? LinearGradient(
                      colors: [
                        accent.withOpacity(0.2),
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.15),
                      ],
                      stops: const [0.0, 0.4, 1.0],
                      begin: Alignment.centerLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: backgroundColor != null
                  ? Color.alphaBlend(accent.withOpacity(0.1), backgroundColor!)
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: iconArea,
                  height: iconArea,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withOpacity(0.15),
                  ),
                  child: _AnimatedIconWidget(
                    key: ValueKey(type),
                    type: type,
                    baseIconColor: accent,
                    size: iconCircle,
                    scale: scale,
                    enableAnimation: enableAnimation, // Pass it down
                  ),
                ),
                SizedBox(width: gap),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: defaultTitleStyle.merge(titleStyle),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 3 * scale),
                      Text(
                        description,
                        style: defaultDescStyle.merge(descriptionStyle),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum ToastType { success, error, warning }

// ---------------------------------------------------------------------------

class _AnimatedIconWidget extends StatefulWidget {
  final ToastType type;
  final Color baseIconColor;
  final double size;
  final double scale;
  final bool enableAnimation;

  const _AnimatedIconWidget({
    super.key,
    required this.type,
    required this.baseIconColor,
    required this.size,
    required this.scale,
    required this.enableAnimation,
  });

  @override
  State<_AnimatedIconWidget> createState() => _AnimatedIconWidgetState();
}

class _AnimatedIconWidgetState extends State<_AnimatedIconWidget>
    with TickerProviderStateMixin {
  late final AnimationController _primaryController;
  AnimationController? _secondaryController;

  @override
  void initState() {
    super.initState();

    // If animations are false, set duration to 0 and advance instantly
    final duration1 = widget.enableAnimation
        ? const Duration(milliseconds: 500)
        : Duration.zero;
    final duration2 = widget.enableAnimation
        ? const Duration(milliseconds: 600)
        : Duration.zero;
    final duration3 = widget.enableAnimation
        ? const Duration(milliseconds: 300)
        : Duration.zero;

    switch (widget.type) {
      case ToastType.success:
        _primaryController = AnimationController(
          vsync: this,
          duration: duration1,
        );
        if (widget.enableAnimation) {
          _primaryController.forward();
        } else {
          _primaryController.value =
              1.0; // Draw fully completed checkmark instantly
        }

      case ToastType.error:
        _primaryController = AnimationController(
          vsync: this,
          duration: duration2,
        );
        if (widget.enableAnimation) {
          _primaryController.repeat(reverse: true);
        } else {
          _primaryController.value = 0.5; // Sit static in the middle of scale
        }

      case ToastType.warning:
        _primaryController = AnimationController(
          vsync: this,
          duration: duration3,
        );
        _secondaryController = AnimationController(
          vsync: this,
          duration: duration1,
        );

        if (widget.enableAnimation) {
          _primaryController.forward().then((_) {
            if (mounted) _secondaryController!.repeat(reverse: true);
          });
        } else {
          // Draw fully completed vertical line and fully visible dot
          _primaryController.value = 1.0;
          _secondaryController!.value = 1.0;
        }
    }
  }

  @override
  void dispose() {
    _primaryController.dispose();
    _secondaryController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final sc = widget.scale;

    switch (widget.type) {
      case ToastType.success:
        return Container(
          width: s,
          height: s,
          decoration: BoxDecoration(
            color: widget.baseIconColor,
            shape: BoxShape.circle,
          ),
          child: AnimatedBuilder(
            animation: _primaryController,
            builder: (_, __) => CustomPaint(
              painter: _CheckmarkPainter(
                progress: _primaryController.value,
                color: const Color(0xFF182025),
                scale: sc,
              ),
            ),
          ),
        );

      case ToastType.warning:
        return Container(
          width: s,
          height: s,
          decoration: BoxDecoration(
            color: widget.baseIconColor,
            shape: BoxShape.circle,
          ),
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _primaryController,
              if (_secondaryController != null) _secondaryController!,
            ]),
            builder: (_, __) => CustomPaint(
              painter: _WarningPainter(
                lineProgress: _primaryController.value,
                dotOpacity: (_secondaryController?.value ?? 1.0).clamp(
                  0.0,
                  1.0,
                ),
                color: const Color(0xFF182025),
                scale: sc,
              ),
            ),
          ),
        );

      case ToastType.error:
        // Use a static container if animations are disabled
        if (!widget.enableAnimation) {
          return Container(
            width: s,
            height: s,
            decoration: BoxDecoration(
              color: widget.baseIconColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.close,
              size: s * 0.6,
              color: const Color(0xFF182025),
            ),
          );
        }

        return ScaleTransition(
          scale: Tween<double>(begin: 0.85, end: 1.15).animate(
            CurvedAnimation(
              parent: _primaryController,
              curve: Curves.easeInOut,
            ),
          ),
          child: Container(
            width: s,
            height: s,
            decoration: BoxDecoration(
              color: widget.baseIconColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.close,
              size: s * 0.6,
              color: const Color(0xFF182025),
            ),
          ),
        );
    }
  }
}

// ---------------------------------------------------------------------------

class _CheckmarkPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double scale;

  const _CheckmarkPainter({
    required this.progress,
    required this.color,
    this.scale = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5 * scale
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(w * 0.29, h * 0.52)
      ..lineTo(w * 0.44, h * 0.67)
      ..lineTo(w * 0.71, h * 0.33);

    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;

    if (progress >= 1.0) {
      canvas.drawPath(path, paint);
    } else {
      final metric = metrics.first;
      canvas.drawPath(metric.extractPath(0, metric.length * progress), paint);
    }
  }

  @override
  bool shouldRepaint(_CheckmarkPainter old) =>
      old.progress != progress || old.scale != scale;
}

// ---------------------------------------------------------------------------

class _WarningPainter extends CustomPainter {
  final double lineProgress;
  final double dotOpacity;
  final Color color;
  final double scale;

  const _WarningPainter({
    required this.lineProgress,
    required this.dotOpacity,
    required this.color,
    this.scale = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    if (lineProgress > 0) {
      canvas.drawLine(
        Offset(w * 0.5, h * 0.18),
        Offset(w * 0.5, h * 0.18 + (h * 0.40) * lineProgress),
        Paint()
          ..color = color
          ..strokeWidth = 2.5 * scale
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      );
    }

    if (dotOpacity > 0) {
      canvas.drawCircle(
        Offset(w * 0.5, h * 0.82),
        w * 0.09,
        Paint()
          ..color = color.withOpacity(dotOpacity)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(_WarningPainter old) =>
      old.lineProgress != lineProgress ||
      old.dotOpacity != dotOpacity ||
      old.scale != scale;
}
