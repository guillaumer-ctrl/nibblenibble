import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefsKey = 'locale';

/// Current app locale. Defaults to French; `main()` overrides the initial
/// value with whatever was persisted last time, read before `runApp` so
/// there's no flash of the wrong language on startup. Device-local (not
/// synced to the account) since it must also apply to the pre-auth
/// Welcome/Sign-in/Sign-up screens.
final localeProvider = StateProvider<Locale>((ref) => const Locale('fr', 'FR'));

Future<Locale> loadSavedLocale() async {
  final prefs = await SharedPreferences.getInstance();
  final code = prefs.getString(_prefsKey);
  switch (code) {
    case 'en':
      return const Locale('en', 'US');
    case 'es':
      return const Locale('es', 'ES');
    default:
      return const Locale('fr', 'FR');
  }
}

Future<void> saveLocale(Locale locale) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_prefsKey, locale.languageCode);
}
