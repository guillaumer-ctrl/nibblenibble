import 'package:flutter/material.dart';

import '../motion/motion.dart';
import '../theme/app_theme.dart';

/// Custom switch: thumb slides, track cross-fades color, `150ms`. Built as a
/// ready-to-use engine piece — no toggle UI exists in the app yet.
class AnimatedToggle extends StatelessWidget {
  const AnimatedToggle({super.key, required this.value, this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  static const _width = 44.0;
  static const _height = 26.0;
  static const _thumbSize = 20.0;
  static const _padding = 3.0;

  @override
  Widget build(BuildContext context) {
    final duration = Motion.reduced(context)
        ? MotionDurations.reduced
        : MotionDurations.micro;
    return GestureDetector(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: AnimatedContainer(
        duration: duration,
        curve: MotionCurves.standard,
        width: _width,
        height: _height,
        padding: const EdgeInsets.all(_padding),
        decoration: BoxDecoration(
          color: value ? AppColors.of(context).sageDark : AppColors.of(context).line,
          borderRadius: BorderRadius.circular(_height / 2),
        ),
        child: AnimatedAlign(
          duration: duration,
          curve: MotionCurves.standard,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: _thumbSize,
            height: _thumbSize,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
