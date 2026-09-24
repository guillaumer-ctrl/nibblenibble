import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_strings.dart';
import '../models/baby_profile.dart';
import '../models/family_invitation.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import 'app_loading_indicator.dart';
import 'app_snackbar.dart';
import 'pressable_scale.dart';

/// Shown on the home screen whenever the signed-in email has pending
/// invitations — this is the only place an invited account learns it's
/// been invited and can actually join the baby's family circle.
class PendingInvitationsCard extends ConsumerStatefulWidget {
  const PendingInvitationsCard({super.key});

  @override
  ConsumerState<PendingInvitationsCard> createState() =>
      _PendingInvitationsCardState();
}

class _PendingInvitationsCardState
    extends ConsumerState<PendingInvitationsCard> {
  // Invitations just accepted/declined by this user, removed from view the
  // instant they tap the button — doesn't wait on the Firestore stream to
  // notice the write, which could lag by a beat (or, for the collectionGroup
  // query behind it, sometimes noticeably longer).
  final _handledIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final invitations = (ref.watch(myPendingInvitationsProvider).value ?? [])
        .where((inv) => !_handledIds.contains(inv.id))
        .toList();
    if (invitations.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.of(context).amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.of(context).amber.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(width: 6),
              Text(
                AppStrings.of(context).pendingInvitation,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                  color: AppColors.of(context).amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...invitations.map(
            (inv) => _InvitationRow(
              invitation: inv,
              onHandled: () => setState(() => _handledIds.add(inv.id)),
            ),
          ),
        ],
      ),
    );
  }
}

class _InvitationRow extends ConsumerStatefulWidget {
  const _InvitationRow({required this.invitation, required this.onHandled});

  final FamilyInvitation invitation;

  /// Called right after accept/decline succeeds, so the parent can remove
  /// this row immediately instead of waiting on the provider to refresh.
  final VoidCallback onHandled;

  @override
  ConsumerState<_InvitationRow> createState() => _InvitationRowState();
}

class _InvitationRowState extends ConsumerState<_InvitationRow> {
  bool _loading = false;
  late final Future<BabyProfile?> _babyFuture;

  @override
  void initState() {
    super.initState();
    // Fetched once and cached here — a FutureBuilder whose `future` is
    // rebuilt inline on every build() re-fires this Firestore read (and
    // flashes back to its loading state) any time an ancestor rebuilds for
    // any reason, not just when this invitation actually changes.
    _babyFuture = ref.read(babyRepositoryProvider).getBaby(widget.invitation.babyId);
  }

  Future<void> _respond(bool accept) async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(familyRepositoryProvider);
      if (accept) {
        final user = ref.read(currentUserProvider);
        await repo.acceptInvitation(
          widget.invitation,
          uid: user.uid,
          // myDisplayNameProvider (Firestore), not Firebase Auth's own
          // displayName — see that provider's doc comment.
          name:
              ref.read(myDisplayNameProvider).value ??
              user.displayName ??
              user.email ??
              AppStrings.of(context).fallbackDisplayName,
          email: user.email ?? widget.invitation.email,
        );
        if (mounted) {
          AppSnackBar.showSuccess(
            context,
            AppStrings.of(context).invitationAccepted,
          );
        }
      } else {
        await repo.declineInvitation(widget.invitation);
      }
      widget.onHandled();
      // watchMyPendingInvitations is a collectionGroup query — its local
      // cache doesn't always reflect this device's own just-committed write
      // as fast as a plain collection query would, so the underlying list
      // can lag. onHandled() above already hid the row instantly; this just
      // keeps the provider itself in sync for next time it's read.
      ref.invalidate(myPendingInvitationsProvider);
    } catch (_) {
      if (mounted) {
        AppSnackBar.showError(context, AppStrings.of(context).processInvitationFailed);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return FutureBuilder<BabyProfile?>(
      future: _babyFuture,
      builder: (context, snapshot) {
        final babyName = snapshot.data?.name ?? s.aBabyProfile;
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  s.joinBabyProfile(babyName),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              if (_loading)
                const AppLoadingIndicator(size: 16)
              else ...[
                PressableScale(
                  child: TextButton(
                    onPressed: () => _respond(false),
                    child: Text(s.decline),
                  ),
                ),
                PressableScale(
                  child: TextButton(
                    onPressed: () => _respond(true),
                    child: Text(s.accept),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
