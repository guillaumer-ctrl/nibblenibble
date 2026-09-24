import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefsKey = 'themeMode';

/// Current app theme mode. Defaults to following the OS; `main()` overrides
/// the initial value with whatever was persisted last time, read before
/// `runApp` so there's no flash of the wrong theme on startup. Device-local
/// (not synced to the account), same as [localeProvider].
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

Future<ThemeMode> loadSavedThemeMode() async {
  final prefs = await SharedPreferences.getInstance();
  switch (prefs.getString(_prefsKey)) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    default:
      return ThemeMode.system;
  }
}

Future<void> saveThemeMode(ThemeMode mode) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_prefsKey, switch (mode) {
    ThemeMode.light => 'light',
    ThemeMode.dark => 'dark',
    ThemeMode.system => 'system',
  });
}
