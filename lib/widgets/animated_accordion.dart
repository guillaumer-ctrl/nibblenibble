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
    final duration = Motion.reduced(context)
        ? MotionDurations.reduced
        : MotionDurations.tab;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        AnimatedSize(
          duration: duration,
          curve: MotionCurves.standard,
          alignment: Alignment.topCenter,
          child: ClipRect(
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
          ),
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
