import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/nibble_wordmark.dart';
import '../../widgets/pressable_scale.dart';
import 'sign_in_screen.dart';
import 'sign_up_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      body: SafeArea(
        child: Stack(
          children: [
            // Soft flat decorative shapes, no gradients.
            Positioned(
              top: -90,
              right: -90,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  color: AppColors.of(context).primaryLight,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -60,
              left: -70,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.of(context).sageLight,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 40, 28, 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const NibbleWordmark(
                    twoLines: true,
                    height: 110,
                    animated: true,
                  ),
                  const SizedBox(height: 22),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: SizedBox(
                          width: 230,
                          child: Text(
                            s.welcomeTagline,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.of(context).inkSoft,
                              fontSize: 14.5,
                              height: 1.6,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 56),
                      PressableScale(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SignUpScreen(),
                            ),
                          ),
                          child: Text(s.getStarted),
                        ),
                      ),
                      const SizedBox(height: 14),
                      PressableScale(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SignInScreen(),
                            ),
                          ),
                          child: Text(
                            s.alreadyHaveAccount,
                            style: TextStyle(
                              color: AppColors.of(context).inkSoft,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
