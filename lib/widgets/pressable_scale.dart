import 'package:flutter/material.dart';

import '../motion/motion.dart';

/// Wraps any tappable child with a quick press-down/release scale
/// (`1 → 0.90 → 1`, with a little spring back on release) for tactile
/// feedback. Uses a [Listener] rather than a tap recognizer so it never
/// competes with the wrapped widget's own gesture handling —
/// `ElevatedButton`, `ChoiceChip`, `InkWell` etc. keep working exactly as
/// before, this only adds a paint-layer transform on top.
class PressableScale extends StatefulWidget {
  const PressableScale({super.key, required this.child});

  final Widget child;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: MotionDurations.micro,
      lowerBound: 0.90,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _press() {
    // Pointer events can still arrive after the widget's gone (e.g. the
    // press navigates away or the item is removed mid-gesture) — context
    // and _controller are both unsafe to touch once that happens.
    if (!mounted || Motion.reduced(context)) return;
    _controller.animateTo(0.90, curve: MotionCurves.standard);
  }

  void _release() {
    if (!mounted || Motion.reduced(context)) return;
    _controller.animateTo(1.0, curve: MotionCurves.bouncy);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _press(),
      onPointerUp: (_) => _release(),
      onPointerCancel: (_) => _release(),
      child: ScaleTransition(scale: _controller, child: widget.child),
    );
  }
}
