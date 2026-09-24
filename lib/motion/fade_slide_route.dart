import 'package:flutter/material.dart';

import 'motion.dart';

/// A lighter push than the app-wide [SlideParallaxRouteBuilder] — fade +
/// a subtle slide-in from the right, no parallax dim of the screen behind.
/// Used for the Account tab's settings sub-pages (Famille, Notifications,
/// Export, Langue, Signaler un bug), where the heavier parallax read as
/// busy for what's really just opening a simple settings page.
///
/// The pop is intentionally shorter than the push: with so little motion in
/// this transition (just a subtle fade/slide, no parallax), the full
/// [MotionDurations.stack] length on the way back read as sluggish —
/// closing a simple settings page should feel snappier than opening it.
const _reversePopDuration = Duration(milliseconds: 260);

Route<T> fadeSlideRoute<T>(WidgetBuilder builder) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => builder(context),
    transitionDuration: MotionDurations.stack,
    reverseTransitionDuration: _reversePopDuration,
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
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.06, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
