import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'consent_service.dart';

/// Google's public TEST app-open ad unit ids — see [BannerAdWidget]'s doc
/// comment for why test ids are always used in debug builds.
const _testAppOpenAdUnitIdAndroid = 'ca-app-pub-3940256099942544/9257395921';
const _testAppOpenAdUnitIdIOS = 'ca-app-pub-3940256099942544/5575463023';

/// nibblenibble's real app-open ad unit (AdMob console > App Open), used in
/// release builds only — see [_testAppOpenAdUnitIdAndroid].
const _realAppOpenAdUnitIdAndroid = 'ca-app-pub-9293680034175956/5133125294';

/// No iOS ad unit exists yet (there's no iOS app registered in AdMob) —
/// null means the release ad simply never preloads/shows on iOS until this
/// is filled in, rather than crashing or wrongly reusing the Android id.
const String? _realAppOpenAdUnitIdIOS = null;

String? get _appOpenAdUnitId {
  final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
  if (kDebugMode) {
    return isIOS ? _testAppOpenAdUnitIdIOS : _testAppOpenAdUnitIdAndroid;
  }
  return isIOS ? _realAppOpenAdUnitIdIOS : _realAppOpenAdUnitIdAndroid;
}

/// Shows a full-screen ad when the user returns to the app after having
/// backgrounded it — not on cold start/first launch (nothing to "return"
/// to yet), and not on a brief interruption like a permission dialog or the
/// system photo picker (see [_minBackgroundDuration]).
///
/// A singleton, constructed once from `main()`: its constructor registers
/// the lifecycle observer, and callers just need to `preload()` after the
/// Mobile Ads SDK is initialized.
class AppOpenAdManager {
  AppOpenAdManager._() {
    WidgetsBinding.instance.addObserver(_LifecycleObserver(this));
  }

  static final AppOpenAdManager instance = AppOpenAdManager._();

  AppOpenAd? _ad;
  DateTime? _loadedAt;
  bool _isShowingAd = false;

  // Google's own guidance: don't show an app-open ad older than 4 hours —
  // stale inventory serves worse creatives and hurts eCPM.
  static const _maxAdAge = Duration(hours: 4);

  // Skip momentary trips out of the app (camera/file picker, a permission
  // prompt, switching to copy a code) so this never fires as an
  // interruption to something the user was mid-task on — only a real
  // "coming back to the app" moment shows the ad.
  static const _minBackgroundDuration = Duration(seconds: 30);

  Future<void> preload() async {
    if (kIsWeb) return;
    if (_ad != null) return; // already have one ready
    final adUnitId = _appOpenAdUnitId;
    if (adUnitId == null) return;
    final canRequest = await ConsentService.instance.canRequestAds;
    if (!canRequest) return;
    await AppOpenAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _loadedAt = DateTime.now();
        },
        onAdFailedToLoad: (_) {},
      ),
    );
  }

  void _showIfAvailable() {
    if (_isShowingAd) return;
    final ad = _ad;
    final loadedAt = _loadedAt;
    if (ad == null || loadedAt == null) return;
    if (DateTime.now().difference(loadedAt) > _maxAdAge) {
      ad.dispose();
      _ad = null;
      preload();
      return;
    }
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) => _isShowingAd = true,
      onAdDismissedFullScreenContent: (ad) {
        _isShowingAd = false;
        ad.dispose();
        _ad = null;
        preload();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        _isShowingAd = false;
        ad.dispose();
        _ad = null;
        preload();
      },
    );
    ad.show();
  }
}

class _LifecycleObserver extends WidgetsBindingObserver {
  _LifecycleObserver(this._manager);

  final AppOpenAdManager _manager;
  DateTime? _backgroundedAt;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _backgroundedAt = DateTime.now();
      return;
    }
    if (state != AppLifecycleState.resumed) return;
    final backgroundedAt = _backgroundedAt;
    _backgroundedAt = null;
    if (backgroundedAt == null) return; // cold start, not a return trip
    if (DateTime.now().difference(backgroundedAt) <
        AppOpenAdManager._minBackgroundDuration) {
      return;
    }
    _manager._showIfAvailable();
  }
}
