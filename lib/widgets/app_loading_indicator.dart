import 'package:flutter/material.dart';

/// Replaces the repeated `SizedBox(height: 16/18, width: 16/18, child:
/// CircularProgressIndicator(strokeWidth: 2, color: ...))` pattern used to
/// show a spinner in place of a button's label, and the plain
/// `Center(child: CircularProgressIndicator())` used for section/page
/// loading states.
class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({super.key, this.size, this.color});

  /// Inline size (e.g. inside a button). Null keeps the default, unconstrained
  /// [CircularProgressIndicator] size used for a full section/page.
  final double? size;
  final Color? color;

  static Widget center({double? size, Color? color}) =>
      Center(child: AppLoadingIndicator(size: size, color: color));

  @override
  Widget build(BuildContext context) {
    final indicator = CircularProgressIndicator(
      strokeWidth: size == null ? 4 : 2,
      color: color,
    );
    if (size == null) return indicator;
    return SizedBox(height: size, width: size, child: indicator);
  }
}
