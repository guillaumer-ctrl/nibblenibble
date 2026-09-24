import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../data/consent_service.dart';

/// Google's public TEST banner unit ids (always serve test ads, safe to
/// commit, one per platform — Android and iOS test/ad-unit ids are never
/// interchangeable) — used for every debug build, so testing on a real
/// device (or in the emulator/simulator) never risks accidentally
/// generating real ad clicks/impressions, which AdMob treats as invalid
/// traffic and can suspend an account over. Real ads only ever serve from a
/// release build.
const _testBannerAdUnitIdAndroid = 'ca-app-pub-3940256099942544/6300978111';
const _testBannerAdUnitIdIOS = 'ca-app-pub-3940256099942544/2934735716';

/// nibblenibble's real banner ad units — one per placement (separate AdMob
/// console entries), so each screen's fill rate/eCPM can be told apart in
/// the dashboard, used in release builds only — see
/// [_testBannerAdUnitIdAndroid].
const homeBannerAdUnitIdAndroid = 'ca-app-pub-9293680034175956/8681488066';
const statsBannerAdUnitIdAndroid = 'ca-app-pub-9293680034175956/9808710781';

/// No iOS ad unit exists yet (there's no iOS app registered in AdMob) —
/// null means the release banner simply doesn't load on iOS until this is
/// filled in, rather than crashing or wrongly reusing the Android id.
const String? _realBannerAdUnitIdIOS = null;

String? _bannerAdUnitId(String androidAdUnitId) {
  final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
  if (kDebugMode) {
    return isIOS ? _testBannerAdUnitIdIOS : _testBannerAdUnitIdAndroid;
  }
  return isIOS ? _realBannerAdUnitIdIOS : androidAdUnitId;
}

/// Backoff schedule for retrying a failed load — a transient miss (no
/// network blip, momentary no-fill) shouldn't permanently cost this
/// impression slot for the rest of the session, but retrying too eagerly
/// risks looking like ad-request abuse to AdMob. Bounded at 3 attempts.
const _retryDelays = [Duration(seconds: 20), Duration(seconds: 45), Duration(seconds: 90)];

/// A banner ad, shown once loaded and collapsing to nothing if it ultimately
/// fails (no network, no fill, etc.) rather than leaving a broken gap.
///
/// Uses an adaptive anchored size (full available width, Google-optimized
/// height) instead of the fixed 320x50 banner — adaptive banners routinely
/// out-earn fixed sizes since more of the surface is sellable inventory, and
/// they're Google's own top recommendation for banner eCPM.
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key, required this.androidAdUnitId});

  /// The real (release-build) Android ad unit id for this placement — see
  /// [homeBannerAdUnitIdAndroid]/[statsBannerAdUnitIdAndroid].
  final String androidAdUnitId;

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _ad;
  int _attempt = 0;
  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) return; // google_mobile_ads doesn't support Flutter web.
    _loadAdIfConsented();
  }

  // RGPD/UMP: never request an ad until consent has been resolved (obtained,
  // or confirmed not required for this user's region) — see ConsentService.
  Future<void> _loadAdIfConsented() async {
    final adUnitId = _bannerAdUnitId(widget.androidAdUnitId);
    if (adUnitId == null) return;
    final canRequest = await ConsentService.instance.canRequestAds;
    if (!canRequest || !mounted) return;

    final width = MediaQuery.sizeOf(context).width.truncate();
    final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSizeWithOrientation(
      Orientation.portrait,
      width,
    );
    if (size == null || !mounted) return;

    final ad = BannerAd(
      adUnitId: adUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _attempt = 0;
          if (mounted) setState(() => _ad = ad as BannerAd);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (!mounted || _attempt >= _retryDelays.length) return;
          final delay = _retryDelays[_attempt];
          _attempt++;
          _retryTimer = Timer(delay, _loadAdIfConsented);
        },
      ),
    );
    ad.load();
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (ad == null) return const SizedBox.shrink();
    return Container(
      alignment: Alignment.center,
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      margin: const EdgeInsets.only(top: 8),
      child: AdWidget(ad: ad),
    );
  }
}
