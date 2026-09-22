import 'package:flutter/material.dart';

/// A circular progress indicator that animates smoothly from 0.0 (or previous value)
/// to the target completeness percentage, featuring synchronized numeric counting
/// and dynamic status colors.
class AnimatedProgressCircle extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final double size;
  final double strokeWidth;
  final bool isDark;
  final TextStyle? textStyle;
  final Duration duration;
  final Curve curve;
  final Color? color;

  const AnimatedProgressCircle({
    super.key,
    required this.value,
    this.size = 56,
    this.strokeWidth = 5,
    required this.isDark,
    this.textStyle,
    this.duration = const Duration(milliseconds: 1000),
    this.curve = Curves.easeOutCubic,
    this.color,
  });

  static Color getStatusColor(double progress) {
    if (progress >= 0.80) {
      return const Color(0xFF00C853);
    } else if (progress >= 0.50) {
      return Colors.amber.shade800;
    } else {
      return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final targetValue = value.isFinite ? value.clamp(0.0, 1.0) : 0.0;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: targetValue),
      duration: duration,
      curve: curve,
      builder: (context, animatedVal, child) {
        final effectiveColor = color ?? getStatusColor(animatedVal);

        return Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                value: animatedVal,
                strokeWidth: strokeWidth,
                strokeCap: StrokeCap.round,
                backgroundColor: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
                valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
              ),
            ),
            Text(
              '${(animatedVal * 100).toStringAsFixed(0)}%',
              style: textStyle ??
                  TextStyle(
                    fontSize: size * 0.24,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0E0E14),
                  ),
            ),
          ],
        );
      },
    );
  }
}
