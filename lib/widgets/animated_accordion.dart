import 'package:flutter/material.dart';

import '../motion/motion.dart';

/// Expandable panel: header stays put, [child] expands/collapses via
/// [AnimatedSize] (no layout jump/thrash), with a chevron that rotates in
/// sync with [expanded].
class AnimatedAccordion extends StatelessWidget {
  const AnimatedAccordion({
    super.key,
    required this.expanded,
    required this.header,
    required this.child,
  });

  final bool expanded;
  final Widget header;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final content = ClipRect(
      child: Align(
        // topLeft, not topCenter — with only heightFactor set, Align
        // fills the full available width and then centers its child
        // horizontally within that box unless told otherwise, which
        // was centering the food chips instead of keeping them flush
        // left like the rest of the accordion content.
        alignment: Alignment.topLeft,
        heightFactor: expanded ? 1.0 : 0.0,
        child: child,
      ),
    );
    // AnimatedSize restarts its internal AnimationController synchronously
    // inside its own performLayout when the target size changes; with a
    // zero duration (reduced motion) that controller completes instantly
    // and re-dirties the render object *while it's still laying out*,
    // which crashes ("RenderAnimatedSize was mutated in its own
    // performLayout implementation" — seen in Crashlytics). Skipping
    // AnimatedSize entirely when reduced avoids ever handing it a zero
    // duration, and matches the accessibility intent anyway (no motion).
    if (Motion.reduced(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [header, content],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        AnimatedSize(
          duration: MotionDurations.tab,
          curve: MotionCurves.standard,
          alignment: Alignment.topCenter,
          child: content,
        ),
      ],
    );
  }
}

/// Chevron icon to place inside [AnimatedAccordion]'s header, rotating
/// `0 → 0.5 turns` in sync with the same `expanded` flag.
class AnimatedAccordionChevron extends StatelessWidget {
  const AnimatedAccordionChevron({
    super.key,
    required this.expanded,
    this.color,
  });

  final bool expanded;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final duration = Motion.reduced(context)
        ? MotionDurations.reduced
        : MotionDurations.tab;
    return AnimatedRotation(
      turns: expanded ? 0.5 : 0.0,
      duration: duration,
      curve: MotionCurves.standard,
      child: Icon(Icons.keyboard_arrow_down, color: color),
    );
  }
}
