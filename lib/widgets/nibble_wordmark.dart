import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../motion/motion.dart';
import '../theme/app_theme.dart';

/// Renders the hand-drawn nibblenibble wordmark, tinted to a given color.
/// [twoLines] uses the reflected "nibble / elbbin" lockup (welcome screen,
/// app icon source); the single-line variant is for the topbar.
class NibbleWordmark extends StatefulWidget {
  const NibbleWordmark({
    super.key,
    this.twoLines = false,
    this.height = 20,
    this.color,
    this.animated = false,
  });

  final bool twoLines;
  final double height;

  /// Tint for the mark. Defaults to primary in light theme / white in dark
  /// theme, matching every current call site (home topbar, welcome screen).
  final Color? color;

  /// Plays a looping animation of permanent bites ("crocs") taken out of
  /// the wordmark, one after another, until it's fully eaten away — then it
  /// fades back in whole and the cycle repeats. A bit of brand personality
  /// for the welcome screen. Off by default (e.g. the topbar mark shouldn't
  /// be permanently mid-chomp).
  final bool animated;

  @override
  State<NibbleWordmark> createState() => _NibbleWordmarkState();
}

class _NibbleWordmarkState extends State<NibbleWordmark>
    with TickerProviderStateMixin {
  // The wordmark is a 2-line lockup, so a 3-col x 2-row grid lines up one
  // cell per line of text. Fixed eating order (not shuffled): bottom-right,
  // top-left, top-right, bottom-middle, top-middle, bottom-left.
  static const _gridCols = 3;
  static const _gridRows = 2;
  static const _biteCenters = [
    Offset(2.5 / _gridCols, 1.5 / _gridRows), // bottom-right
    Offset(0.5 / _gridCols, 0.5 / _gridRows), // top-left
    Offset(2.5 / _gridCols, 0.5 / _gridRows), // top-right
    Offset(1.5 / _gridCols, 1.5 / _gridRows), // bottom-middle
    Offset(1.5 / _gridCols, 0.5 / _gridRows), // top-middle
    Offset(0.5 / _gridCols, 1.5 / _gridRows), // bottom-left
  ];

  // Relative offsets (fraction of one grid cell) of the 4 teeth within a
  // single croc, arranged in a tight cluster so together they blot out
  // their cell.
  static const _toothOffsets = [
    Offset(-0.4, 0.1),
    Offset(-0.14, -0.35),
    Offset(0.14, -0.35),
    Offset(0.4, 0.1),
  ];

  final _random = Random();

  late final AnimationController _controller;
  late final AnimationController _fadeController;
  // Drives a very slight overshoot-then-settle scale when the wordmark
  // fades back in whole, so it pops back rather than just materializing.
  // easeOutBack overshoots past 1.0 mid-curve and settles back to exactly
  // 1.0 by the time the controller finishes — harmless the rest of the
  // time, when the controller just sits at its resting value of 1.
  late final Animation<double> _bounce = CurvedAnimation(
    parent: _fadeController,
    curve: Curves.easeOutBack,
  ).drive(Tween(begin: 0.85, end: 1.0));
  // Every croc up to (not including) this index is a permanent, fully-grown
  // bite; -1 means the wordmark is whole (not started yet, or just faded
  // back in after being fully eaten).
  int _biteIndex = -1;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      // Starts invisible so the very first appearance plays the same
      // pop-in bounce as every later reappearance, instead of just
      // materializing at full scale.
      value: 0,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // MediaQuery (read inside Motion.reduced) can only be looked up once
    // this Element is fully attached — initState() is too early. The
    // _started guard just keeps this from re-triggering on later
    // dependency changes (e.g. a reduced-motion toggle mid-animation).
    if (!_started) {
      _started = true;
      if (widget.animated && !Motion.reduced(context)) {
        _loop();
      } else {
        // No animation loop will ever run to bring it in — show it as-is.
        _fadeController.value = 1;
      }
    }
  }

  Future<void> _loop() async {
    // Same pop-in bounce as the post-chomp reappearance, played once up
    // front instead of the wordmark just materializing.
    await _fadeController.forward(from: 0);
    if (!mounted) return;
    // A beat before the first croc, so the whole wordmark is visible for a
    // moment rather than starting to get eaten the instant it appears.
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    while (mounted) {
      for (var i = 0; i < _biteCenters.length; i++) {
        setState(() => _biteIndex = i);
        await _controller.forward(from: 0);
        if (!mounted) return;
        // Random pacing between crocs instead of a metronome.
        await Future.delayed(
          Duration(milliseconds: 40 + _random.nextInt(150)),
        );
        if (!mounted) return;
      }
      // Fully eaten — hold a beat, then fade back in whole.
      await Future.delayed(const Duration(milliseconds: 650));
      if (!mounted) return;
      setState(() => _biteIndex = -1);
      await _fadeController.forward(from: 0);
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tint = widget.color ??
        (Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : AppColors.of(context).primary);
    final mark = SvgPicture.asset(
      widget.twoLines
          ? 'assets/branding/logo-2-lines.svg'
          : 'assets/branding/logo-1-line.svg',
      height: widget.height,
      colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
    );
    if (!widget.animated) return mark;

    return ScaleTransition(
      scale: _bounce,
      child: FadeTransition(
        opacity: _fadeController,
        child: AnimatedBuilder(
          animation: _controller,
          child: mark,
          builder: (context, child) => ClipPath(
            clipper: _BiteClipper(
              biteCenters: _biteCenters,
              toothOffsets: _toothOffsets,
              gridCols: _gridCols,
              gridRows: _gridRows,
              biteIndex: _biteIndex,
              currentProgress: _controller.value,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _BiteClipper extends CustomClipper<Path> {
  const _BiteClipper({
    required this.biteCenters,
    required this.toothOffsets,
    required this.gridCols,
    required this.gridRows,
    required this.biteIndex,
    required this.currentProgress,
  });

  final List<Offset> biteCenters;
  final List<Offset> toothOffsets;
  final int gridCols;
  final int gridRows;
  final int biteIndex;
  final double currentProgress;

  @override
  Path getClip(Size size) {
    var path = Path()..addRect(Offset.zero & size);
    final cellWidth = size.width / gridCols;
    final cellHeight = size.height / gridRows;
    // Sized to cover one grid cell once combined with its 3 siblings, so a
    // completed run of crocs leaves no gaps — kept modest so each
    // individual croc still reads as a small bite, not a huge chunk.
    final radius = 0.62 * (cellWidth > cellHeight ? cellWidth : cellHeight);

    for (var i = 0; i < biteCenters.length; i++) {
      final double progress;
      if (i < biteIndex) {
        progress = 1;
      } else if (i == biteIndex) {
        progress = currentProgress;
      } else {
        continue;
      }
      if (progress <= 0) continue;
      final cellCenter = Offset(
        biteCenters[i].dx * size.width,
        biteCenters[i].dy * size.height,
      );
      for (final tooth in toothOffsets) {
        final center =
            cellCenter + Offset(tooth.dx * cellWidth, tooth.dy * cellHeight);
        final bite = Path()
          ..addOval(Rect.fromCircle(center: center, radius: radius * progress));
        path = Path.combine(PathOperation.difference, path, bite);
      }
    }
    return path;
  }

  @override
  bool shouldReclip(covariant _BiteClipper oldClipper) =>
      oldClipper.biteIndex != biteIndex ||
      oldClipper.currentProgress != currentProgress;
}
