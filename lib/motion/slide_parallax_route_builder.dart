import 'package:flutter/material.dart';

import 'motion.dart';

/// App-wide Stack Push/Pop transition: the incoming route slides in from the
/// right while fading in, and whatever route it covers recedes slightly
/// (parallax) and dims. Registered once in [PageTransitionsTheme] so every
/// existing `MaterialPageRoute` push site in the app gets this for free —
/// no per-screen changes, and Android/iOS both keep their native
/// edge-swipe-back gesture since this only swaps the *paint*, not the
/// `Navigator`'s own pop-gesture handling.
class SlideParallaxRouteBuilder extends PageTransitionsBuilder {
  const SlideParallaxRouteBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (Motion.reduced(context)) {
      return FadeTransition(opacity: animation, child: child);
    }

    // No reverseCurve: with one, a pop plays the flipped (ease-in / snap-at-
    // the-end) curve, which reads as noticeably quicker than the push even
    // at the exact same duration — human perception weights how a motion
    // *ends* heavily, and rushing the finish reads as "faster". Reusing the
    // same ease-out curve both ways keeps the pop feeling as unhurried as
    // the push, at an identical duration.
    final incoming = CurvedAnimation(
      parent: animation,
      curve: MotionCurves.standard,
    );
    final outgoing = CurvedAnimation(
      parent: secondaryAnimation,
      curve: MotionCurves.standard,
    );

    final slideIn = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(incoming);
    final recede = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.2, 0),
    ).animate(outgoing);
    final fadeIn = Tween<double>(begin: 0, end: 1).animate(incoming);
    final dim = Tween<double>(begin: 1, end: 0.7).animate(outgoing);

    return AnimatedBuilder(
      animation: Listenable.merge([incoming, outgoing]),
      child: child,
      builder: (context, child) {
        return FractionalTranslation(
          translation: slideIn.value + recede.value,
          child: Opacity(opacity: fadeIn.value * dim.value, child: child),
        );
      },
    );
  }
}
