import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/pressable_scale.dart';
import 'onboarding_choice_screen.dart';

/// Short skippable walkthrough shown once, right after account creation.
class IntroTutorialScreen extends StatefulWidget {
  const IntroTutorialScreen({super.key});

  @override
  State<IntroTutorialScreen> createState() => _IntroTutorialScreenState();
}

class _IntroTutorialScreenState extends State<IntroTutorialScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const OnboardingChoiceScreen()),
    );
  }

  void _next(int pageCount) {
    if (_page == pageCount - 1) {
      _finish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final colors = AppColors.of(context);
    final pages = [
      (Icons.restaurant_menu_rounded, s.introLogTitle, s.introLogBody),
      (Icons.bar_chart_rounded, s.introStatsTitle, s.introStatsBody),
      (Icons.family_restroom_rounded, s.introFamilyTitle, s.introFamilyBody),
    ];
    final isLast = _page == pages.length - 1;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 12, 0),
                child: TextButton(
                  onPressed: _finish,
                  child: Text(s.introSkip),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  for (final (icon, title, body) in pages)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: colors.primaryLight,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              icon,
                              size: 56,
                              color: colors.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 12),
                          Text(body, textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < pages.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _page ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _page ? colors.primary : colors.line,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: PressableScale(
                  child: ElevatedButton(
                    onPressed: () => _next(pages.length),
                    child: Text(isLast ? s.introStart : s.introNext),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
