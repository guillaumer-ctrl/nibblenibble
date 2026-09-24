import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import 'app_loading_indicator.dart';
import 'pressable_scale.dart';

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.loading = false,
  });

  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      child: OutlinedButton(
        onPressed: loading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.of(context).ink,
          backgroundColor: AppColors.of(context).card,
          side: BorderSide(color: AppColors.of(context).line),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
        child: loading
            ? const AppLoadingIndicator(size: 18)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'G',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      // Google's brand blue — intentionally outside
                      // AppColorsX, not a theme-bypass bug.
                      color: Color(0xFF4285F4),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    AppStrings.of(context).continueWithGoogle,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
