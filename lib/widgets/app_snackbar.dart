import 'dart:async';

import 'package:flutter/material.dart';

import '../app.dart';
import '../motion/motion.dart';
import '../theme/app_theme.dart';

/// One place for the app's confirmation/error popups instead of each screen
/// hand-rolling `ScaffoldMessenger.of(context).showSnackBar(SnackBar(...))`.
/// Shown as a pill at the top of the screen (inserted into the root
/// [Overlay] via [rootNavigatorKey], so it survives whichever screen is on
/// top and any navigation that happens while it's up) rather than Material's
/// bottom SnackBar.
class AppSnackBar {
  AppSnackBar._();

  static OverlayEntry? _entry;
  static GlobalKey<_ToastPillState>? _key;
  static Timer? _timer;

  static void show(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    Color? foregroundColor,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final colors = AppColors.of(context);
    _insert(
      message: message,
      backgroundColor: backgroundColor ?? colors.ink,
      foregroundColor: foregroundColor ?? colors.background,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Same as [showError], but for code paths with no live [BuildContext]
  /// left (e.g. a delete flow that already popped its screen). Falls back to
  /// the platform brightness instead of `Theme.of(context)`.
  static void showErrorNoContext(String message) {
    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final colors = brightness == Brightness.dark
        ? AppColorsX.dark
        : AppColorsX.light;
    _insert(
      message: message,
      backgroundColor: colors.red,
      foregroundColor: Colors.white,
      duration: const Duration(seconds: 4),
    );
  }

  static void _insert({
    required String message,
    required Color backgroundColor,
    required Color foregroundColor,
    required Duration duration,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final overlay = rootNavigatorKey.currentState?.overlay;
    if (overlay == null) return;
    _dismissImmediately();

    final key = GlobalKey<_ToastPillState>();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _ToastPill(
        key: key,
        message: message,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        actionLabel: actionLabel,
        onAction: onAction == null
            ? null
            : () {
                onAction();
                _requestDismiss();
              },
        onDismiss: _requestDismiss,
      ),
    );
    _entry = entry;
    _key = key;
    overlay.insert(entry);
    _timer = Timer(duration, _requestDismiss);
  }

  static void showSuccess(BuildContext context, String message) {
    final colors = AppColors.of(context);
    show(
      context,
      message,
      backgroundColor: colors.sageDark,
      foregroundColor: Colors.white,
    );
  }

  static void showError(BuildContext context, String message) {
    final colors = AppColors.of(context);
    show(
      context,
      message,
      backgroundColor: colors.red,
      foregroundColor: Colors.white,
      duration: const Duration(seconds: 4),
    );
  }

  static void showAction(
    BuildContext context,
    String message, {
    required String actionLabel,
    required VoidCallback onAction,
    Duration duration = const Duration(seconds: 6),
  }) {
    show(
      context,
      message,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Plays the pill's exit animation before actually removing the overlay
  /// entry — tapping the pill, its action, the auto-dismiss timer, and a new
  /// toast replacing this one all funnel through here.
  static void _requestDismiss() {
    _timer?.cancel();
    _timer = null;
    final key = _key;
    final entry = _entry;
    _key = null;
    _entry = null;
    final state = key?.currentState;
    if (state == null) {
      entry?.remove();
      return;
    }
    state.dismiss().then((_) => entry?.remove());
  }

  /// Used when a new toast is about to replace one already on screen — no
  /// point animating out a pill that's being instantly swapped.
  static void _dismissImmediately() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
    _key = null;
  }
}

class _ToastPill extends StatefulWidget {
  const _ToastPill({
    super.key,
    required this.message,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onDismiss,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final Color backgroundColor;
  final Color foregroundColor;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onDismiss;

  @override
  State<_ToastPill> createState() => _ToastPillState();
}

class _ToastPillState extends State<_ToastPill>
    with TickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 250);

  // Kept as two separate controllers on purpose: the pill should only ever
  // slide down once, on the way in, and settle there — dismissing it just
  // fades it out in place rather than sliding it back up. Reversing a
  // single shared controller would undo the slide too.
  late final AnimationController _slideController;
  late final AnimationController _opacityController;
  bool _startedEntrance = false;
  bool _dismissing = false;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(vsync: this, duration: _duration);
    _opacityController = AnimationController(
      vsync: this,
      duration: _duration,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_startedEntrance) return;
    _startedEntrance = true;
    if (Motion.reduced(context)) {
      _slideController.value = 1;
      _opacityController.value = 1;
    } else {
      _slideController.forward();
      _opacityController.forward();
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _opacityController.dispose();
    super.dispose();
  }

  /// Fades the pill out in place. Returns once it's fully invisible so the
  /// caller can safely remove the [OverlayEntry] behind it.
  Future<void> dismiss() async {
    if (_dismissing) return;
    _dismissing = true;
    if (!mounted) return;
    if (Motion.reduced(context)) return;
    await _opacityController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    // Slide gets a playful little overshoot on the way in; opacity stays on
    // a plain curve since FadeTransition can't take a curve that dips
    // outside 0..1 the way a back-out curve briefly does.
    final opacity = CurvedAnimation(
      parent: _opacityController,
      curve: MotionCurves.standard,
      reverseCurve: MotionCurves.standard,
    );
    final slide = CurvedAnimation(
      parent: _slideController,
      curve: MotionCurves.bouncy,
    );

    return Positioned(
      top: 0,
      left: 16,
      right: 16,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Center(
            child: FadeTransition(
              opacity: opacity,
              child: SlideTransition(
                position: slide.drive(
                  Tween<Offset>(begin: const Offset(0, -1.2), end: Offset.zero),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: GestureDetector(
                    onTap: widget.onDismiss,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 13,
                      ),
                      decoration: BoxDecoration(
                        color: widget.backgroundColor,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              widget.message,
                              style: TextStyle(
                                color: widget.foregroundColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 13.5,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.actionLabel != null &&
                              widget.onAction != null) ...[
                            const SizedBox(width: 14),
                            GestureDetector(
                              onTap: widget.onAction,
                              child: Text(
                                widget.actionLabel!,
                                style: TextStyle(
                                  color: widget.foregroundColor,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.5,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
