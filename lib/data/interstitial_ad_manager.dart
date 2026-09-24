import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'consent_service.dart';

/// Google's public TEST interstitial ad unit ids — see [BannerAdWidget]'s
/// doc comment for why test ids are always used in debug builds.
const _testInterstitialAdUnitIdAndroid =
    'ca-app-pub-3940256099942544/1033173712';
const _testInterstitialAdUnitIdIOS = 'ca-app-pub-3940256099942544/4411468910';

/// nibblenibble's real interstitial ad unit (AdMob console > Export PDF -
/// Interstitiel), used in release builds only — see
/// [_testInterstitialAdUnitIdAndroid].
const _realInterstitialAdUnitIdAndroid =
    'ca-app-pub-9293680034175956/8934612811';

/// No iOS ad unit exists yet either (there's no iOS app registered in
/// AdMob) — same reasoning as the Android id above.
const String? _realInterstitialAdUnitIdIOS = null;

String? get _interstitialAdUnitId {
  final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
  if (kDebugMode) {
    return isIOS
        ? _testInterstitialAdUnitIdIOS
        : _testInterstitialAdUnitIdAndroid;
  }
  return isIOS ? _realInterstitialAdUnitIdIOS : _realInterstitialAdUnitIdAndroid;
}

const _retryDelays = [
  Duration(seconds: 20),
  Duration(seconds: 45),
  Duration(seconds: 90),
];

/// Shows a full-screen interstitial at a natural transition point — right
/// now, only after a PDF export finishes (see ExportPdfScreen).
///
/// Capped at once per app session: a parent exporting the PDF is likely to
/// repeat the action a few times in a row (tweaking what they're sharing,
/// re-sending it to someone else), and showing a full-screen ad every
/// single time would turn a deliberately "occasional" placement into
/// exactly the ad-spam that hurts retention long-term.
class InterstitialAdManager {
  InterstitialAdManager._();
  static final InterstitialAdManager instance = InterstitialAdManager._();

  InterstitialAd? _ad;
  bool _shownThisSession = false;
  int _attempt = 0;

  Future<void> preload() async {
    if (kIsWeb) return;
    if (_shownThisSession || _ad != null) return;
    final adUnitId = _interstitialAdUnitId;
    if (adUnitId == null) return;
    final canRequest = await ConsentService.instance.canRequestAds;
    if (!canRequest) return;
    await InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _attempt = 0;
        },
        onAdFailedToLoad: (_) {
          if (_attempt >= _retryDelays.length) return;
          final delay = _retryDelays[_attempt];
          _attempt++;
          Timer(delay, preload);
        },
      ),
    );
  }

  /// No-op if nothing's loaded yet or the session's single interstitial has
  /// already been shown — callers don't need to check first, and can just
  /// fire-and-forget this after whatever action should trigger it.
  Future<void> showIfAvailable() async {
    if (_shownThisSession) return;
    final ad = _ad;
    if (ad == null) {
      unawaited(preload()); // ready for next time, even if not this one
      return;
    }
    _shownThisSession = true;
    final completer = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _ad = null;
        if (!completer.isCompleted) completer.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _ad = null;
        if (!completer.isCompleted) completer.complete();
      },
    );
    await ad.show();
    return completer.future;
  }
}
