import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_strings.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/pressable_scale.dart';
import 'add_baby_screen.dart';
import 'root_shell.dart';

/// Right after sign-up: a new account might be starting its own baby's
/// profile, or might exist only because someone invited them to an
/// existing one — forcing everyone through "Ajouter un bébé" first ignored
/// the second case entirely. This branches before either path starts.
class OnboardingChoiceScreen extends ConsumerStatefulWidget {
  const OnboardingChoiceScreen({super.key});

  @override
  ConsumerState<OnboardingChoiceScreen> createState() =>
      _OnboardingChoiceScreenState();
}

class _OnboardingChoiceScreenState
    extends ConsumerState<OnboardingChoiceScreen> {
  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final invitations = ref.watch(myPendingInvitationsProvider).value;
    // Hide the invitations option only once we're sure there are none —
    // while still loading (null), show it rather than flash it away.
    final showInvitations = invitations == null || invitations.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(title: Text(s.welcome)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                s.gettingStarted,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                s.onboardingChoiceQuestion,
              ),
              const SizedBox(height: 28),
              PressableScale(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AddBabyScreen(onboarding: true),
                    ),
                  ),
                  child: Text(s.addMyBabyProfile),
                ),
              ),
              if (showInvitations) ...[
                const SizedBox(height: 12),
                PressableScale(
                  child: OutlinedButton(
                    // No dedicated invitations screen — the home screen's
                    // PendingInvitationsCard already surfaces and handles
                    // every pending invitation for this account, so this
                    // just gets the user there instead of duplicating it.
                    onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const RootShell()),
                      (route) => false,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.of(context).ink,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                    child: Text(
                      invitations != null && invitations.isNotEmpty
                          ? s.seeMyInvitation(invitations.length)
                          : s.iReceivedAnInvitation,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
