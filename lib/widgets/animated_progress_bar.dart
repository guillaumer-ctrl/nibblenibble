import 'package:flutter/material.dart';

import '../motion/motion.dart';

/// Drop-in replacement for `LinearProgressIndicator(value: ...)` that tweens
/// from its previous value to the new one instead of jumping straight to it.
class AnimatedProgressBar extends StatelessWidget {
  const AnimatedProgressBar({
    super.key,
    required this.value,
    this.backgroundColor,
    this.color,
    this.minHeight,
    this.borderRadius,
  });

  final double value;
  final Color? backgroundColor;
  final Color? color;
  final double? minHeight;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final reduced = Motion.reduced(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
      duration: reduced ? MotionDurations.reduced : MotionDurations.gauge,
      curve: reduced ? Curves.linear : MotionCurves.gauge,
      builder: (context, animatedValue, _) {
        final indicator = LinearProgressIndicator(
          value: animatedValue,
          backgroundColor: backgroundColor,
          color: color,
          minHeight: minHeight,
        );
        if (borderRadius == null) return indicator;
        return ClipRRect(borderRadius: borderRadius!, child: indicator);
      },
    );
  }
}
