import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/auth_providers.dart';
import 'providers/locale_provider.dart';
import 'providers/theme_mode_provider.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/root_shell.dart';
import 'theme/app_theme.dart';
import 'widgets/app_loading_indicator.dart';
import 'widgets/error_retry_view.dart';
import 'widgets/offline_banner.dart';
import 'widgets/responsive_center.dart';

/// Lets code that no longer has a live [BuildContext] (e.g. a delete flow
/// that pops its screen before an async operation finishes) still surface a
/// SnackBar on whatever screen the user ends up on.
final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// Gives [AppSnackBar] an [Overlay] to insert its top pill into regardless
/// of which screen is currently on top.
final rootNavigatorKey = GlobalKey<NavigatorState>();

class NibbleNibbleApp extends ConsumerWidget {
  const NibbleNibbleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      title: 'nibblenibble',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: locale,
      supportedLocales: const [
        Locale('fr', 'FR'),
        Locale('en', 'US'),
        Locale('es', 'ES'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) =>
          ResponsiveCenter(child: OfflineBanner(child: child!)),
      home: const AuthGate(),
    );
  }
}

/// Swaps between the auth flow and the app itself as sign-in state changes.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) => user == null ? const WelcomeScreen() : const RootShell(),
      // Matches the native splash screen's background so there's no visual
      // jump between the OS splash and the app taking over.
      loading: () => Scaffold(
        backgroundColor: AppColors.of(context).primary,
        body: Center(
          child: AppLoadingIndicator(color: AppColors.of(context).onPrimary),
        ),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: AppColors.of(context).background,
        body: ErrorRetryView(onRetry: () => ref.invalidate(authStateProvider)),
      ),
    );
  }
}
