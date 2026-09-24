import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_strings.dart';
import '../providers/theme_mode_provider.dart';
import '../theme/app_theme.dart';

class ThemeScreen extends ConsumerWidget {
  const ThemeScreen({super.key});

  Future<void> _select(WidgetRef ref, ThemeMode mode) async {
    ref.read(themeModeProvider.notifier).state = mode;
    await saveThemeMode(mode);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppStrings.of(context);
    final current = ref.watch(themeModeProvider);
    final options = <(ThemeMode, String)>[
      (ThemeMode.light, s.themeLight),
      (ThemeMode.dark, s.themeDark),
      (ThemeMode.system, s.themeSystem),
    ];

    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(title: Text(s.theme)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.of(context).card,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: AppColors.of(context).line),
              ),
              // ListTile paints ink/background on the nearest Material
              // ancestor — without this, the Container's own color hides it.
              child: Material(
                type: MaterialType.transparency,
                child: Column(
                  children: [
                    for (final (mode, label) in options)
                      ListTile(
                        title: Text(label),
                        trailing: mode == current
                            ? Icon(
                                Icons.check_circle,
                                color: AppColors.of(context).sageDark,
                              )
                            : null,
                        onTap: () => _select(ref, mode),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
