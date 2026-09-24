import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_strings.dart';
import '../providers/locale_provider.dart';
import '../theme/app_theme.dart';

class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  Future<void> _select(WidgetRef ref, Locale locale) async {
    ref.read(localeProvider.notifier).state = locale;
    await saveLocale(locale);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppStrings.of(context);
    final current = ref.watch(localeProvider);
    final options = <(Locale, String)>[
      (const Locale('fr', 'FR'), s.french),
      (const Locale('en', 'US'), s.english),
      (const Locale('es', 'ES'), s.spanish),
    ];

    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(title: Text(s.language)),
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
                    for (final (locale, label) in options)
                      ListTile(
                        title: Text(label),
                        trailing: locale.languageCode == current.languageCode
                            ? Icon(
                                Icons.check_circle,
                                color: AppColors.of(context).sageDark,
                              )
                            : null,
                        onTap: () => _select(ref, locale),
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
