import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'data/app_open_ad_manager.dart';
import 'data/consent_service.dart';
import 'data/interstitial_ad_manager.dart';
import 'providers/locale_provider.dart';
import 'providers/theme_mode_provider.dart';

Future<void> main() async {
  // runZonedGuarded so an error escaping the widget tree (not caught by
  // FlutterError.onError, e.g. inside a Future not awaited by any widget)
  // still reaches Crashlytics instead of just being lost to the console.
  runZonedGuarded(_run, (error, stack) {
    if (!kIsWeb) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    }
  });
}

Future<void> _run() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR');
  await initializeDateFormatting('en_US');
  // Read before runApp so there's no flash of the default (French) locale
  // before the saved preference loads.
  final savedLocale = await loadSavedLocale();
  final savedThemeMode = await loadSavedThemeMode();
  // Web isn't registered as a Firebase app yet (only Android, via
  // google-services.json) — skip so `flutter run -d chrome` still works
  // for quick UI previews. Crashlytics itself doesn't support web either.
  if (!kIsWeb) {
    await Firebase.initializeApp();
    FlutterError.onError = (details) {
      // Flutter's "A RenderFlex overflowed" debug banner is reported
      // through FlutterError.onError like a real error, but the code that
      // paints it only runs inside an assert — i.e. never in a release
      // build. Recording it as fatal misrepresented Crashlytics' crash-free
      // rate with something the app can't actually crash on in production;
      // it's still worth fixing as a layout bug, just not as a fatal.
      if (details.exception.toString().startsWith(
        'A RenderFlex overflowed',
      )) {
        FirebaseCrashlytics.instance.recordFlutterError(details);
        return;
      }
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
    // Consent gathering and Ads SDK init both involve a network round-trip
    // (UMP consent check, ad SDK init) — awaiting them here would hold the
    // native splash screen up for however long that takes (seconds, on a
    // slow connection). Nothing about showing the app depends on them:
    // BannerAdWidget/AppOpenAdManager/InterstitialAdManager all already
    // check ConsentService.canRequestAds before requesting an ad, so it's
    // safe to resolve consent and init Ads in the background after the
    // first frame instead of blocking startup on it.
    unawaited(_initAdsInBackground());
  }
  runApp(
    ProviderScope(
      overrides: [
        localeProvider.overrideWith((ref) => savedLocale),
        themeModeProvider.overrideWith((ref) => savedThemeMode),
      ],
      child: const NibbleNibbleApp(),
    ),
  );
}

Future<void> _initAdsInBackground() async {
  // RGPD/UMP: must gather (or confirm not required) consent before the
  // Mobile Ads SDK is initialized, so no ad is ever requested ahead of it.
  await ConsentService.instance.gatherConsent();
  await MobileAds.instance.initialize();
  // Not ready yet the very first time the user backgrounds/resumes the app
  // is fine — it'll be ready for the next.
  unawaited(AppOpenAdManager.instance.preload());
  unawaited(InterstitialAdManager.instance.preload());
}
