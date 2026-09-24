import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_check_mark.dart';

/// Shown for a few seconds right after onboarding finishes (baby profile
/// created, family invited), then advances on its own — mirrors
/// AccountCreatedScreen's celebratory-then-auto-advance pattern.
class BabyCreatedScreen extends StatefulWidget {
  const BabyCreatedScreen({super.key});

  @override
  State<BabyCreatedScreen> createState() => _BabyCreatedScreenState();
}

class _BabyCreatedScreenState extends State<BabyCreatedScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2600), () {
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedCheckMark(
                backgroundColor: AppColors.of(context).primary,
                strokeColor: AppColors.of(context).primaryLight,
              ),
              const SizedBox(height: 28),
              Text(
                s.profileCreatedTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              Text(s.profileCreatedSubtitle, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
