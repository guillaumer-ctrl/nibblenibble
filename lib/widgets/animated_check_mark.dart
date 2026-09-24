import 'package:flutter/material.dart';

import '../motion/motion.dart';

/// The validation checkmark used on both success screens: the circle pops
/// in with a little spring, then the check stroke draws itself on.
class AnimatedCheckMark extends StatefulWidget {
  const AnimatedCheckMark({
    super.key,
    this.size = 104,
    required this.backgroundColor,
    required this.strokeColor,
  });

  final double size;
  final Color backgroundColor;
  final Color strokeColor;

  @override
  State<AnimatedCheckMark> createState() => _AnimatedCheckMarkState();
}

class _AnimatedCheckMarkState extends State<AnimatedCheckMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _strokeProgress;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );
    _scale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.55, curve: MotionCurves.bouncy),
    );
    _strokeProgress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 1.0, curve: Curves.easeOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (Motion.reduced(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Transform.scale(
          scale: _scale.value.clamp(0.0, 1.5),
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              shape: BoxShape.circle,
            ),
            child: CustomPaint(
              painter: _CheckStrokePainter(
                color: widget.strokeColor,
                progress: _strokeProgress.value,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CheckStrokePainter extends CustomPainter {
  _CheckStrokePainter({required this.color, required this.progress});

  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.28, h * 0.52)
      ..lineTo(w * 0.44, h * 0.68)
      ..lineTo(w * 0.74, h * 0.34);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.09
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (progress >= 1) {
      canvas.drawPath(path, paint);
      return;
    }

    // Draw only the leading `progress` fraction of the check's total
    // length, so the stroke appears to trace itself on.
    final metrics = path.computeMetrics().toList();
    final totalLength = metrics.fold<double>(0, (sum, m) => sum + m.length);
    var remaining = totalLength * progress;
    for (final metric in metrics) {
      if (remaining <= 0) break;
      final extractLength = remaining.clamp(0, metric.length);
      canvas.drawPath(
        metric.extractPath(0, extractLength.toDouble()),
        paint,
      );
      remaining -= metric.length;
    }
  }

  @override
  bool shouldRepaint(covariant _CheckStrokePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.progress != progress;
}
