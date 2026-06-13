import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Buddy mood — drives the face and the floating animation.
enum BuddyMood { idle, listening, happy, cheering, sad }

/// A cute, hand-drawn style AI buddy built entirely with
/// Flutter primitives — no external assets needed.
///
/// The widget is intentionally lightweight:
///   - one CustomPainter for the body (cheap, no raster)
///   - one AnimationController for the float/bounce (rebuilt only
///     inside the widget, so other widgets don't repaint)
///
/// Why a custom painter? Bitmap assets balloon APK size and
/// don't scale crisply on mid-range Android. Pure-vector Custom
/// Painters paint fast and stay sharp on any device.
class BuddyWidget extends StatefulWidget {
  final BuddyMood mood;
  final double size;

  const BuddyWidget({
    super.key,
    this.mood = BuddyMood.idle,
    this.size = 160,
  });

  @override
  State<BuddyWidget> createState() => _BuddyWidgetState();
}

class _BuddyWidgetState extends State<BuddyWidget>
    with TickerProviderStateMixin {
  late final AnimationController _float;
  late final AnimationController _blink;
  late final AnimationController _cheer;

  @override
  void initState() {
    super.initState();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _cheer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scheduleBlink();
  }

  void _scheduleBlink() {
    Future.delayed(const Duration(seconds: 3), () async {
      if (!mounted) return;
      await _blink.forward();
      await _blink.reverse();
      if (mounted) _scheduleBlink();
    });
  }

  @override
  void didUpdateWidget(covariant BuddyWidget old) {
    super.didUpdateWidget(old);
    if (widget.mood == BuddyMood.cheering && old.mood != BuddyMood.cheering) {
      _cheer.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _float.dispose();
    _blink.dispose();
    _cheer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_float, _blink, _cheer]),
      builder: (context, _) {
        final floatY = -6 + 6 * _float.value; // gentle bob
        final cheerScale = widget.mood == BuddyMood.cheering
            ? 1.0 + 0.08 * _cheer.value
            : 1.0;
        return Transform.translate(
          offset: Offset(0, floatY),
          child: Transform.scale(
            scale: cheerScale,
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: CustomPaint(
                painter: _BuddyPainter(
                  mood: widget.mood,
                  blink: _blink.value,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BuddyPainter extends CustomPainter {
  final BuddyMood mood;
  final double blink; // 0..1

  _BuddyPainter({required this.mood, required this.blink});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    // Soft shadow
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.10)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, h * 0.92),
        width: w * 0.55,
        height: h * 0.08,
      ),
      shadow,
    );

    // Body — round robot head
    final bodyColor = _bodyColor();
    final bodyRect = Rect.fromCenter(
      center: Offset(center.dx, h * 0.45),
      width: w * 0.75,
      height: h * 0.75,
    );
    final rrect = RRect.fromRectAndRadius(bodyRect, Radius.circular(w * 0.25));
    canvas.drawRRect(rrect, Paint()..color = bodyColor);

    // Antenna
    final antennaPaint = Paint()
      ..color = AppColors.inkDark
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(center.dx, h * 0.10),
      Offset(center.dx, h * 0.20),
      antennaPaint,
    );
    canvas.drawCircle(
      Offset(center.dx, h * 0.10),
      5,
      Paint()..color = AppColors.coral,
    );

    // Cheek blush
    final blush = Paint()..color = AppColors.coral.withValues(alpha: 0.45);
    canvas.drawCircle(Offset(w * 0.27, h * 0.55), 7, blush);
    canvas.drawCircle(Offset(w * 0.73, h * 0.55), 7, blush);

    // Eyes — blink by squashing the height
    final eyePaint = Paint()..color = AppColors.inkDark;
    final eyeY = h * 0.45;
    final eyeHeightClosed = 2.0;
    final eyeHeightOpen = 11.0;
    final eyeHeight = eyeHeightOpen * (1 - blink) + eyeHeightClosed * blink;
    final leftEye = Rect.fromCenter(
      center: Offset(w * 0.38, eyeY),
      width: 9,
      height: eyeHeight,
    );
    final rightEye = Rect.fromCenter(
      center: Offset(w * 0.62, eyeY),
      width: 9,
      height: eyeHeight,
    );
    canvas.drawOval(leftEye, eyePaint);
    canvas.drawOval(rightEye, eyePaint);

    // Mouth — varies by mood
    final mouthPaint = Paint()
      ..color = AppColors.inkDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final mouthCenter = Offset(center.dx, h * 0.62);
    switch (mood) {
      case BuddyMood.idle:
        canvas.drawArc(
          Rect.fromCenter(
            center: mouthCenter,
            width: 22,
            height: 10,
          ),
          0.1,
          3.0,
          false,
          mouthPaint,
        );
        break;
      case BuddyMood.listening:
        canvas.drawOval(
          Rect.fromCenter(
            center: mouthCenter,
            width: 8,
            height: 8,
          ),
          Paint()..color = AppColors.inkDark,
        );
        break;
      case BuddyMood.happy:
        canvas.drawArc(
          Rect.fromCenter(
            center: mouthCenter,
            width: 24,
            height: 14,
          ),
          0.2,
          2.7,
          false,
          mouthPaint,
        );
        break;
      case BuddyMood.cheering:
        canvas.drawArc(
          Rect.fromCenter(
            center: mouthCenter,
            width: 30,
            height: 22,
          ),
          0.1,
          3.0,
          false,
          mouthPaint,
        );
        break;
      case BuddyMood.sad:
        canvas.drawArc(
          Rect.fromCenter(
            center: mouthCenter.translate(0, 4),
            width: 20,
            height: 12,
          ),
          3.3,
          2.7,
          false,
          mouthPaint,
        );
        break;
    }

    // Cheer sparkles
    if (mood == BuddyMood.cheering) {
      final sparkle = Paint()..color = AppColors.accent;
      canvas.drawCircle(Offset(w * 0.15, h * 0.25), 4, sparkle);
      canvas.drawCircle(Offset(w * 0.85, h * 0.30), 3, sparkle);
      canvas.drawCircle(Offset(w * 0.10, h * 0.55), 2.5, sparkle);
    }
  }

  Color _bodyColor() {
    switch (mood) {
      case BuddyMood.idle:
        return AppColors.skyBlue;
      case BuddyMood.listening:
        return AppColors.mint;
      case BuddyMood.happy:
      case BuddyMood.cheering:
        return AppColors.accent;
      case BuddyMood.sad:
        return AppColors.skyBlue.withValues(alpha: 0.7);
    }
  }

  @override
  bool shouldRepaint(covariant _BuddyPainter old) =>
      old.mood != mood || old.blink != blink;
}
