import 'package:flutter/material.dart';

/// Shared timing tokens for every animation in the app — kept in one place
/// so a duration/curve change never has to be hunted down site by site.
class MotionDurations {
  MotionDurations._();

  static const micro = Duration(milliseconds: 180);
  static const tab = Duration(milliseconds: 220);
  static const stack = Duration(milliseconds: 320);
  static const sheet = Duration(milliseconds: 300);
  static const gauge = Duration(milliseconds: 500);
  static const list = Duration(milliseconds: 280);
  static const reduced = Duration.zero;
}

class MotionCurves {
  MotionCurves._();

  static const standard = Cubic(0.2, 0.8, 0.2, 1);
  static const gauge = Cubic(0.16, 1, 0.3, 1);

  /// Slight overshoot/bounce for presses and pops — the app's animations
  /// lean playful rather than minimal, so scale/pop feedback should land
  /// with a little spring rather than settling flat.
  static const bouncy = Cubic(0.34, 1.56, 0.64, 1);
}

/// Flutter's actual equivalent of `prefers-reduced-motion: reduce` — reads
/// the OS-level "remove animations" accessibility setting. Every animated
/// widget in lib/motion and lib/widgets checks this and, when true, swaps
/// its transform/slide for a plain opacity fade over [MotionDurations.reduced]
/// instead of skipping the flag independently.
class Motion {
  Motion._();

  static bool reduced(BuildContext context) =>
      MediaQuery.of(context).disableAnimations;
}
