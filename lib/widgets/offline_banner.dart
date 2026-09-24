import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';

/// A slim banner pinned above the whole app, shown only while the device has
/// no network connection. Firestore's offline cache keeps most screens
/// readable regardless, but anything that actually needs the network (saving
/// a new meal, accepting an invitation, ads) silently queues or fails —
/// this makes that state visible instead of surprising.
class OfflineBanner extends StatefulWidget {
  const OfflineBanner({super.key, required this.child});

  final Widget child;

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  bool _offline = false;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  @override
  void initState() {
    super.initState();
    Connectivity().checkConnectivity().then(_update);
    _subscription = Connectivity().onConnectivityChanged.listen(_update);
  }

  void _update(List<ConnectivityResult> results) {
    if (!mounted) return;
    setState(
      () => _offline = results.every((r) => r == ConnectivityResult.none),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_offline)
          SafeArea(
            bottom: false,
            child: Container(
              width: double.infinity,
              color: AppColors.of(context).amber,
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                AppStrings.of(context).offlineBanner,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.of(context).onAmber,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        Expanded(child: widget.child),
      ],
    );
  }
}
