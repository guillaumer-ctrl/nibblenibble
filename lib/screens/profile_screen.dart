import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/firebase/firestore_instance.dart';
import '../data/repositories/auth_repository.dart';
import '../l10n/app_strings.dart';
import '../models/user_role.dart';
import '../providers/app_providers.dart';
import '../providers/auth_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/app_loading_indicator.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/confirm_delete_dialog.dart';
import '../widgets/pressable_scale.dart';

/// Reached by tapping the name/email summary card on [AccountScreen] —
/// holds the actually-mutating account actions (rename, sign out, delete)
/// so the main Compte list stays a plain settings menu.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  bool _saving = false;
  bool _deletingAccount = false;

  @override
  void initState() {
    super.initState();
    // Prefer the Firestore-stored pseudo (myDisplayNameProvider) over
    // Firebase Auth's own displayName — see that provider's doc comment for
    // why Firebase's copy can't be trusted as the source of truth for a
    // Google-signed-in account.
    _nameController = TextEditingController(
      text:
          ref.read(myDisplayNameProvider).value ??
          ref.read(currentUserProvider).displayName ??
          '',
    );
    _emailController = TextEditingController(
      text: ref.read(currentUserProvider).email ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    try {
      final uid = ref.read(currentUserProvider).uid;
      await ref.read(authRepositoryProvider).updateDisplayName(name);
      // The app's actual source of truth for the display name — see
      // myDisplayNameProvider's doc comment. Firebase's own displayName
      // (set just above) is kept in sync too since other things read it
      // (e.g. the invitation-accept fallback), but Google Sign-In can
      // silently overwrite that copy on a later sign-in, so nothing in
      // this app's own UI should treat it as authoritative anymore.
      await appFirestore.collection('users').doc(uid).set({
        'displayName': name,
      }, SetOptions(merge: true));
      // The member doc's `name` is a snapshot taken when this account
      // joined each baby (creator or invite acceptance) — it never updates
      // on its own, so Famille would otherwise keep showing the old name
      // forever after a rename here.
      final familyRepo = ref.read(familyRepositoryProvider);
      final babies = await ref.read(babyRepositoryProvider).watchBabies().first;
      for (final baby in babies) {
        await familyRepo.updateMemberName(baby.id, uid, name);
      }
      if (mounted) {
        FocusScope.of(context).unfocus();
        AppSnackBar.showSuccess(context, AppStrings.of(context).nameUpdated);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _signOut() async {
    try {
      await ref.read(authRepositoryProvider).signOut();
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (_) {
      if (mounted) {
        AppSnackBar.showError(context, AppStrings.of(context).genericErrorMessage);
      }
    }
  }

  Future<void> _deleteAccount() async {
    final s = AppStrings.of(context);
    setState(() => _deletingAccount = true);
    try {
      final user = ref.read(currentUserProvider);
      final babyRepo = ref.read(babyRepositoryProvider);
      final familyRepo = ref.read(familyRepositoryProvider);
      final babies = await babyRepo.watchBabies().first;

      // Block if this account is the *sole* admin on any baby — deleting it
      // would leave that baby with no one able to manage it.
      for (final baby in babies) {
        final members = await familyRepo.getMembers(baby.id);
        final admins = members.where((m) => m.role == UserRole.admin);
        final isSoleAdmin = admins.length == 1 && admins.first.id == user.uid;
        if (isSoleAdmin) {
          if (mounted) {
            await showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: AppColors.of(context).card,
                title: Text(s.cannotDeleteAccountTitle),
                content: Text(s.cannotDeleteAccountMessage(baby.name)),
                actions: [
                  PressableScale(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(s.understood),
                    ),
                  ),
                ],
              ),
            );
          }
          return;
        }
      }

      if (!mounted) return;
      final nameToType =
          ref.read(myDisplayNameProvider).value ??
          user.displayName ??
          user.email ??
          s.fallbackDisplayName;
      final confirmed = await showTypeToConfirmDeleteDialog(
        context,
        title: s.deleteAccountTitle,
        message: s.deleteAccountMessage,
        nameToType: nameToType,
        confirmLabel: s.deleteMyAccount,
      );
      if (!confirmed) return;

      // Leave every baby's family circle and delete the /users/{uid} record
      // before deleting the auth account itself — once it's gone,
      // request.auth is null and further writes as this user would be
      // rejected by the rules anyway.
      for (final baby in babies) {
        await familyRepo.removeMember(baby.id, user.uid);
      }
      await appFirestore.collection('users').doc(user.uid).delete();
      await ref.read(authRepositoryProvider).deleteAccount();
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } on AuthException catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, s.authErrorMessage(e.code));
      }
    } catch (_) {
      if (mounted) {
        AppSnackBar.showError(context, s.deleteAccountFailed);
      }
    } finally {
      if (mounted) setState(() => _deletingAccount = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(title: Text(s.myProfile)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: s.firstName,
                suffixIcon: IconButton(
                  tooltip: s.save,
                  icon: _saving
                      ? const AppLoadingIndicator(size: 16)
                      : const Icon(Icons.check, size: 20),
                  onPressed: _saving ? null : _saveName,
                ),
              ),
              textCapitalization: TextCapitalization.words,
              onSubmitted: (_) => _saveName(),
            ),
            const SizedBox(height: 4),
            Text(s.firstNameHelper),
            const SizedBox(height: 14),
            TextField(
              enabled: false,
              controller: _emailController,
              decoration: InputDecoration(labelText: s.email),
            ),
            const SizedBox(height: 28),
            PressableScale(
              child: OutlinedButton.icon(
                onPressed: _signOut,
                icon: const Icon(Icons.logout, size: 18),
                label: Text(s.signOut),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: PressableScale(
                child: TextButton(
                  onPressed: _deletingAccount ? null : _deleteAccount,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.of(context).red,
                  ),
                  child: _deletingAccount
                      ? const AppLoadingIndicator(size: 16)
                      : Text(s.deleteMyAccount),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
