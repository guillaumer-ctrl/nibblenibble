import 'package:flutter/material.dart';

import '../motion/motion.dart';

/// A `ListView` for stream-driven data (a fresh `List<T>` on every snapshot,
/// not imperative insert/remove calls) that animates the difference between
/// builds instead of hard-cutting to the new list: a newly-appeared id
/// slides down + fades in, and one that dropped out of [items] is kept
/// mounted for one extra beat as a "ghost" row so its removal — a height
/// collapse + fade — is actually visible before it's really gone.
class AnimatedDiffList<T> extends StatefulWidget {
  const AnimatedDiffList({
    super.key,
    required this.items,
    required this.keyOf,
    required this.itemBuilder,
    this.padding,
  });

  final List<T> items;
  final Object Function(T item) keyOf;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final EdgeInsetsGeometry? padding;

  @override
  State<AnimatedDiffList<T>> createState() => _AnimatedDiffListState<T>();
}

class _AnimatedDiffListState<T> extends State<AnimatedDiffList<T>> {
  final Map<Object, T> _ghosts = {};

  @override
  void didUpdateWidget(covariant AnimatedDiffList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newKeys = widget.items.map(widget.keyOf).toSet();
    final duration = Motion.reduced(context)
        ? MotionDurations.reduced
        : MotionDurations.list;
    for (final item in oldWidget.items) {
      final key = widget.keyOf(item);
      if (newKeys.contains(key) || _ghosts.containsKey(key)) continue;
      _ghosts[key] = item;
      Future.delayed(duration, () {
        if (!mounted) return;
        setState(() => _ghosts.remove(key));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduced = Motion.reduced(context);
    return ListView(
      padding: widget.padding,
      children: [
        for (final item in widget.items)
          _AnimatedDiffRow(
            key: ValueKey(widget.keyOf(item)),
            reduced: reduced,
            child: widget.itemBuilder(context, item),
          ),
        for (final ghost in _ghosts.values)
          _AnimatedDiffRow(
            key: ValueKey('ghost-${widget.keyOf(ghost)}'),
            reduced: reduced,
            removing: true,
            child: widget.itemBuilder(context, ghost),
          ),
      ],
    );
  }
}

class _AnimatedDiffRow extends StatelessWidget {
  const _AnimatedDiffRow({
    super.key,
    required this.reduced,
    this.removing = false,
    required this.child,
  });

  final bool reduced;
  final bool removing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final duration = reduced ? MotionDurations.reduced : MotionDurations.list;
    final curve = reduced ? Curves.linear : MotionCurves.standard;

    if (removing) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 1.0, end: 0.0),
        duration: duration,
        curve: curve,
        child: child,
        builder: (context, t, child) {
          if (reduced) return Opacity(opacity: t, child: child);
          return ClipRect(
            child: Align(
              alignment: Alignment.topCenter,
              heightFactor: t.clamp(0.0, 1.0),
              child: Opacity(opacity: t, child: child),
            ),
          );
        },
      );
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      curve: curve,
      child: child,
      builder: (context, t, child) {
        if (reduced) return Opacity(opacity: t, child: child);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, -12 * (1 - t)),
            child: child,
          ),
        );
      },
    );
  }
}
