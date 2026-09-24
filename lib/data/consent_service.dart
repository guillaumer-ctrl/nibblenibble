import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Google's User Messaging Platform (UMP) SDK, bundled inside
/// google_mobile_ads — gathers RGPD-required ad consent from users in the
/// EEA/UK before any ad is requested. The actual consent message/privacy
/// policy link is configured server-side in the AdMob console (Privacy &
/// messaging); this only drives that flow from the app.
class ConsentService {
  ConsentService._();
  static final ConsentService instance = ConsentService._();

  /// Requests a consent info update and shows the consent form if the
  /// user's region requires one. Resolves once it's safe to decide whether
  /// ads can be requested — on success, on failure (e.g. no network), or on
  /// timeout, never left hanging: a stuck native UMP call must not block
  /// app startup, same reasoning as NotificationsService's `_ensureInitialized`.
  Future<void> gatherConsent() {
    final completer = Completer<void>();
    void complete() {
      if (!completer.isCompleted) completer.complete();
    }

    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(
        // Forces the EEA consent flow to appear for debug builds regardless
        // of the tester's actual location, so it can be tested/reviewed —
        // real (release) builds get the flow only where actually required.
        consentDebugSettings: kDebugMode
            ? ConsentDebugSettings(debugGeography: DebugGeography.debugGeographyEea)
            : null,
      ),
      () async {
        try {
          await ConsentForm.loadAndShowConsentFormIfRequired((_) {});
        } catch (_) {
          // Best-effort — see class doc comment.
        }
        complete();
      },
      (_) => complete(),
    );

    return completer.future.timeout(const Duration(seconds: 10), onTimeout: () {});
  }

  /// Whether the app is currently allowed to request ads at all — false
  /// while a required consent form hasn't been resolved yet.
  Future<bool> get canRequestAds => ConsentInformation.instance.canRequestAds();

  /// Whether the "Préférences publicitaires" entry point must be shown in
  /// settings (RGPD requires the user be able to revisit/change consent).
  Future<bool> get privacyOptionsRequired async =>
      await ConsentInformation.instance.getPrivacyOptionsRequirementStatus() ==
      PrivacyOptionsRequirementStatus.required;

  Future<void> showPrivacyOptionsForm() =>
      ConsentForm.showPrivacyOptionsForm((_) {});
}
