import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import 'pressable_scale.dart';

/// Replaces raw `Exception: ...` text on a failed stream/future with a
/// friendly message and a way to actually do something about it — the
/// caller wires [onRetry] to `ref.invalidate(...)` on whichever provider
/// failed, which forces it to re-subscribe/re-fetch.
class ErrorRetryView extends StatelessWidget {
  const ErrorRetryView({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: AppColors.of(context).red, size: 32),
            const SizedBox(height: 12),
            Text(
              s.genericErrorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.of(context).inkSoft),
            ),
            const SizedBox(height: 16),
            PressableScale(
              child: OutlinedButton(onPressed: onRetry, child: Text(s.retry)),
            ),
          ],
        ),
      ),
    );
  }
}
