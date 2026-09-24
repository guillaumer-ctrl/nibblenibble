import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_strings.dart';
import '../models/user_role.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/app_loading_indicator.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/confirm_delete_dialog.dart';
import '../widgets/error_retry_view.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/role_badge.dart';
import 'baby_created_screen.dart';

class FamilyScreen extends ConsumerStatefulWidget {
  const FamilyScreen({super.key, this.onboarding = false});

  /// True when reached as step 3 of sign-up (right after creating the
  /// baby) — shows a step label and a "Terminer" action to head to Home
  /// instead of just a bare back arrow.
  final bool onboarding;

  @override
  ConsumerState<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends ConsumerState<FamilyScreen> {
  final _emailController = TextEditingController();
  UserRole _inviteRole = UserRole.readOnly;
  bool _sending = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendInvite() async {
    final s = AppStrings.of(context);
    final email = _emailController.text.trim();
    if (!email.contains('@')) {
      AppSnackBar.show(context, s.invalidEmailAddress);
      return;
    }
    final baby = ref.read(selectedBabyProvider);
    if (baby == null) return;
    setState(() => _sending = true);
    try {
      await ref
          .read(familyRepositoryProvider)
          .invite(baby.id, email, _inviteRole);
      _emailController.clear();
      if (mounted) {
        setState(() => _inviteRole = UserRole.readOnly);
        AppSnackBar.showSuccess(context, s.invitationSentTo(email));
      }
    } catch (_) {
      if (mounted) {
        AppSnackBar.showError(context, s.invitationSendFailed);
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final baby = ref.watch(selectedBabyProvider);
    final membersAsync = ref.watch(familyMembersProvider);
    final invitationsAsync = ref.watch(familyInvitationsProvider);
    final isAdmin = ref.watch(isCurrentUserAdminProvider);
    final myUid = ref.watch(currentMemberIdProvider);

    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(title: Text(s.family)),
      body: SafeArea(
        child: baby == null
            ? Center(child: Text(s.addBabyToManageFamily))
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (widget.onboarding) ...[
                    Text(
                      s.inviteFamilyIntro(baby.name),
                      style: TextStyle(
                        color: AppColors.of(context).inkSoft,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (isAdmin) ...[
                    Text(
                      s.inviteALovedOne,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.roleExplainer,
                      style: TextStyle(
                        color: AppColors.of(context).inkSoft,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: PressableScale(
                            child: ChoiceChip(
                              label: Text(s.readOnly),
                              selected: _inviteRole == UserRole.readOnly,
                              selectedColor: AppColors.of(context).sage
                                  .withValues(alpha: 0.3),
                              checkmarkColor: AppColors.of(context).sageDark,
                              labelStyle: TextStyle(
                                color: _inviteRole == UserRole.readOnly
                                    ? AppColors.of(context).sageDark
                                    : AppColors.of(context).ink,
                                fontWeight: _inviteRole == UserRole.readOnly
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                              ),
                              onSelected: (_) => setState(
                                () => _inviteRole = UserRole.readOnly,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: PressableScale(
                            child: ChoiceChip(
                              label: Text(s.admin),
                              selected: _inviteRole == UserRole.admin,
                              selectedColor: AppColors.of(context).sage
                                  .withValues(alpha: 0.3),
                              checkmarkColor: AppColors.of(context).sageDark,
                              labelStyle: TextStyle(
                                color: _inviteRole == UserRole.admin
                                    ? AppColors.of(context).sageDark
                                    : AppColors.of(context).ink,
                                fontWeight: _inviteRole == UserRole.admin
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                              ),
                              onSelected: (_) =>
                                  setState(() => _inviteRole = UserRole.admin),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _emailController,
                            decoration: InputDecoration(labelText: s.email),
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ),
                        const SizedBox(width: 8),
                        PressableScale(
                          child: ElevatedButton(
                            onPressed: _sending ? null : _sendInvite,
                            child: _sending
                                ? AppLoadingIndicator(size: 16, color: AppColors.of(context).onPrimary)
                                : Text(s.invite),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    invitationsAsync.when(
                      data: (invitations) => invitations.isEmpty
                          ? const SizedBox.shrink()
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.pendingInvitations,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 12),
                                ...invitations.map(
                                  (inv) => Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.of(context).card,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: AppColors.of(context).line,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(child: Text(inv.email)),
                                        const _PendingPill(),
                                        const SizedBox(width: 4),
                                        Tooltip(
                                          message: s.cancelInvitationTooltip,
                                          child: InkWell(
                                            onTap: () async {
                                              try {
                                                await ref
                                                    .read(
                                                      familyRepositoryProvider,
                                                    )
                                                    .cancelInvitation(
                                                      baby.id,
                                                      inv.id,
                                                    );
                                              } catch (_) {
                                                if (context.mounted) {
                                                  AppSnackBar.showError(
                                                    context,
                                                    s.cancelInvitationFailed,
                                                  );
                                                }
                                              }
                                            },
                                            child: Padding(
                                              padding: const EdgeInsets.all(4),
                                              child: Icon(
                                                Icons.close,
                                                size: 16,
                                                color: AppColors.of(context)
                                                    .inkSoft,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 28),
                              ],
                            ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                  ],
                  Text(
                    s.familyMembers,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  membersAsync.when(
                    data: (members) => Column(
                      children: members
                          .map(
                            (m) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.of(context).card,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.card,
                                ),
                                border: Border.all(
                                  color: AppColors.of(context).line,
                                ),
                              ),
                              // The "⋮" menu button (other members, when
                              // admin) enforces its own minimum tap-target
                              // height — without this, a card lacking it
                              // (e.g. "moi", or any row when not admin)
                              // ends up visibly shorter than the rest.
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minHeight: 44,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            m.id == myUid
                                                ? '${m.name} ${s.me}'
                                                : m.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            m.email,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppColors.of(context)
                                                  .inkSoft,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    RoleBadge(role: m.role),
                                    if (isAdmin && m.id != myUid) ...[
                                      const SizedBox(width: 4),
                                      PopupMenuButton<String>(
                                        tooltip: s.moreOptionsTooltip,
                                        icon: Icon(
                                          Icons.more_vert,
                                          size: 18,
                                          color: AppColors.of(context).inkSoft,
                                        ),
                                        onSelected: (value) async {
                                          final repo = ref.read(
                                            familyRepositoryProvider,
                                          );
                                          try {
                                            if (value == 'toggle-role') {
                                              await repo.updateMemberRole(
                                                baby.id,
                                                m.id,
                                                m.role == UserRole.admin
                                                    ? UserRole.readOnly
                                                    : UserRole.admin,
                                              );
                                            } else if (value == 'remove') {
                                              final confirmed =
                                                  await showConfirmDeleteDialog(
                                                    context,
                                                    title: s.removeMemberTitle(
                                                      m.name,
                                                    ),
                                                    message: s
                                                        .removeMemberMessage(
                                                          m.name,
                                                        ),
                                                    confirmLabel: s.remove,
                                                  );
                                              if (confirmed) {
                                                await repo.removeMember(
                                                  baby.id,
                                                  m.id,
                                                );
                                              }
                                            }
                                          } catch (_) {
                                            if (context.mounted) {
                                              AppSnackBar.showError(
                                                context,
                                                value == 'remove'
                                                    ? s.removeMemberFailed
                                                    : s.updateRoleFailed,
                                              );
                                            }
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          PopupMenuItem(
                                            value: 'toggle-role',
                                            child: Text(
                                              m.role == UserRole.admin
                                                  ? s.switchToReadOnly
                                                  : s.switchToAdmin,
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 'remove',
                                            child: Text(s.remove),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    loading: () => AppLoadingIndicator.center(),
                    error: (_, _) => ErrorRetryView(
                      onRetry: () => ref.invalidate(familyMembersProvider),
                    ),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: widget.onboarding
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: PressableScale(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const BabyCreatedScreen(),
                      ),
                    ),
                    child: Text(s.finish),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

class _PendingPill extends StatelessWidget {
  const _PendingPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.of(context).amber.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Text(
        AppStrings.of(context).pending,
        style: AppTextStyles.badge(context, color: AppColors.of(context).amber),
      ),
    );
  }
}
