import 'package:flutter/material.dart';

import 'motion.dart';

/// A modal-style push that slides up from the bottom (+ fades in) instead of
/// the app-wide slide-from-right of [SlideParallaxRouteBuilder] — used for
/// screens that feel more like a sheet/modal action than a drill-down, e.g.
/// adding or editing a meal.
Route<T> slideUpRoute<T>(WidgetBuilder builder) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => builder(context),
    transitionDuration: MotionDurations.stack,
    reverseTransitionDuration: MotionDurations.stack,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (Motion.reduced(context)) {
        return FadeTransition(opacity: animation, child: child);
      }
      // No reverseCurve — see slide_parallax_route_builder.dart's comment:
      // the flipped curve made the pop feel faster than the push despite an
      // identical duration.
      final curved = CurvedAnimation(
        parent: animation,
        curve: MotionCurves.standard,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(opacity: curved, child: child),
      );
    },
  );
}
