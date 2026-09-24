import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Centers the app's phone-optimized UI in a fixed-width column on screens
/// wider than a phone (tablets, unfolded foldables) instead of stretching
/// every list, form and button full-width edge to edge. Below the
/// breakpoint this is a no-op passthrough — phones are unaffected.
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({super.key, required this.child});

  final Widget child;

  static const double _maxWidth = 600;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width <= _maxWidth) return child;
    return ColoredBox(
      color: AppColors.of(context).background,
      child: Center(
        child: SizedBox(width: _maxWidth, child: child),
      ),
    );
  }
}
