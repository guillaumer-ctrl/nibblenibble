import 'dart:ui';

import 'package:flutter/material.dart';

import '../motion/motion.dart';
import '../theme/app_theme.dart';

/// A bottom sheet built on `showGeneralDialog` instead of
/// `showModalBottomSheet` — the stock widget applies its slide-up transition
/// to *everything* the builder returns, backdrop included, which made the
/// dark scrim look like it was sliding up from the bottom along with the
/// sheet instead of just fading in. Driving the backdrop and the sheet off
/// the same [animation] but through separate transitions (fade vs. slide)
/// fixes that: the scrim fades in place, only the sheet itself slides.
Future<T?> showAnimatedModalBottomSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  Color? backgroundColor,
  ShapeBorder? shape,
}) {
  final reduced = Motion.reduced(context);
  final duration = reduced ? MotionDurations.reduced : MotionDurations.sheet;

  return showGeneralDialog<T>(
    context: context,
    barrierLabel: 'Dismiss',
    barrierDismissible: true,
    barrierColor: Colors.transparent,
    transitionDuration: duration,
    pageBuilder: (context, animation, secondaryAnimation) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: GestureDetector(
          // Swallow taps so they don't fall through to the backdrop below
          // and dismiss the sheet.
          onTap: () {},
          child: Material(
            color: backgroundColor ?? AppColors.of(context).card,
            shape:
                shape ??
                const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
            child: SafeArea(top: false, child: builder(context)),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, sheet) {
      // No reverseCurve — see slide_parallax_route_builder.dart's comment:
      // the flipped curve made the pop feel faster than the push despite an
      // identical duration.
      final curved = CurvedAnimation(
        parent: animation,
        curve: MotionCurves.standard,
      );

      final backdrop = AnimatedBuilder(
        animation: curved,
        builder: (context, _) {
          final t = curved.value;
          return Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8 * t, sigmaY: 8 * t),
                child: Container(
                  color: AppColors.of(context).ink.withValues(alpha: 0.45 * t),
                ),
              ),
            ),
          );
        },
      );

      final animatedSheet = reduced
          ? FadeTransition(opacity: animation, child: sheet)
          : SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(curved),
              child: sheet,
            );

      return Stack(children: [backdrop, animatedSheet]);
    },
  );
}
