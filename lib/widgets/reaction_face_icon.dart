import 'package:flutter/material.dart';

import '../models/reaction.dart';
import '../motion/motion.dart';

/// A small custom-drawn face: plain circle outline + a mouth stroke that varies by
/// reaction — a smile arc for "Aimé", a straight line for "Mitigé", a frown
/// arc for "Pas aimé". Replaces the earlier Material sentiment icons.
class ReactionFaceIcon extends StatelessWidget {
  const ReactionFaceIcon({
    super.key,
    required this.reaction,
    required this.color,
    this.size = 16,
  });

  final Reaction reaction;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: Motion.reduced(context)
          ? MotionDurations.reduced
          : MotionDurations.micro,
      // The incoming/outgoing animation stays linear here; the bounce is
      // applied only to the scale below, since FadeTransition asserts its
      // opacity stays within 0..1 and a back-out curve briefly dips outside
      // that range.
      transitionBuilder: (child, animation) {
        final opacity = CurvedAnimation(
          parent: animation,
          curve: MotionCurves.standard,
        );
        final scale = CurvedAnimation(
          parent: animation,
          curve: MotionCurves.bouncy,
        );
        return FadeTransition(
          opacity: opacity,
          child: ScaleTransition(scale: scale, child: child),
        );
      },
      child: CustomPaint(
        key: ValueKey(reaction),
        size: Size.square(size),
        painter: _ReactionFacePainter(reaction: reaction, color: color),
      ),
    );
  }
}

class _ReactionFacePainter extends CustomPainter {
  _ReactionFacePainter({required this.reaction, required this.color});

  final Reaction reaction;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.09;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - stroke;

    // Circle outline (the face).
    canvas.drawCircle(center, radius, paint);

    // Mouth.
    final mouthWidth = size.width * 0.44;
    final mouthDy = size.height * 0.16;
    final mouthRect = Rect.fromCenter(
      center: center + Offset(0, mouthDy),
      width: mouthWidth,
      height: mouthWidth * 0.7,
    );
    final mouthPath = Path();
    switch (reaction) {
      case Reaction.aime:
        // Smile: an upward arc, raised the same amount as the frown so
        // both sit at a similar height on the face.
        mouthPath.addArc(
          mouthRect.translate(0, -mouthWidth * 0.35),
          0.15 * 3.14159,
          0.7 * 3.14159,
        );
        break;
      case Reaction.mitige:
        // Straight line.
        mouthPath
          ..moveTo(center.dx - mouthWidth / 2, center.dy + mouthDy)
          ..lineTo(center.dx + mouthWidth / 2, center.dy + mouthDy);
        break;
      case Reaction.pasAime:
        // Frown: a downward arc, mirrored above the same mouth line as the
        // smile arc so all three reactions share one baseline.
        mouthPath.addArc(mouthRect, 1.15 * 3.14159, 0.7 * 3.14159);
        break;
    }
    canvas.drawPath(mouthPath, paint);
  }

  @override
  bool shouldRepaint(covariant _ReactionFacePainter oldDelegate) =>
      oldDelegate.reaction != reaction || oldDelegate.color != color;
}
