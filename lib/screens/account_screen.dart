import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/consent_service.dart';
import '../l10n/app_strings.dart';
import '../motion/fade_slide_route.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/pressable_scale.dart';
import 'bug_report_screen.dart';
import 'export_pdf_screen.dart';
import 'family_screen.dart';
import 'language_screen.dart';
import 'profile_screen.dart';
import 'theme_screen.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

const _privacyPolicyUrl = 'https://nibblenibble.app/privacy-policy.html';
const _termsOfServiceUrl = 'https://nibblenibble.app/terms-of-service.html';

class _AccountScreenState extends ConsumerState<AccountScreen> {
  bool _showAdPreferences = false;

  @override
  void initState() {
    super.initState();
    // RGPD: only shown for users whose region requires an ad-consent
    // choice in the first place (see ConsentService).
    ConsentService.instance.privacyOptionsRequired.then((required) {
      if (mounted && required) setState(() => _showAdPreferences = true);
    });
  }

  Future<void> _openUrl(String url) async {
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && mounted) {
      AppSnackBar.showError(context, AppStrings.of(context).openLinkFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(title: Text(s.myAccount)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _ProfileSummaryCard(
              onTap: () =>
                  Navigator.of(context)
                      .push(fadeSlideRoute((_) => const ProfileScreen())),
            ),
            const SizedBox(height: 28),
            _SectionLabel(s.accountFamilyDataSection),
            _SettingsTile(
              icon: Icons.groups_outlined,
              label: s.family,
              onTap: () =>
                  Navigator.of(context)
                      .push(fadeSlideRoute((_) => const FamilyScreen())),
            ),
            _SettingsTile(
              icon: Icons.picture_as_pdf_outlined,
              label: s.dataScreenTitle,
              onTap: () =>
                  Navigator.of(context)
                      .push(fadeSlideRoute((_) => const ExportPdfScreen())),
            ),
            const SizedBox(height: 20),
            _SectionLabel(s.accountPreferencesSection),
            _SettingsTile(
              icon: Icons.language_outlined,
              label: s.language,
              onTap: () =>
                  Navigator.of(context)
                      .push(fadeSlideRoute((_) => const LanguageScreen())),
            ),
            _SettingsTile(
              icon: Icons.dark_mode_outlined,
              label: s.theme,
              onTap: () =>
                  Navigator.of(context)
                      .push(fadeSlideRoute((_) => const ThemeScreen())),
            ),
            if (_showAdPreferences)
              _SettingsTile(
                icon: Icons.ads_click_outlined,
                label: s.adPreferences,
                onTap: () => ConsentService.instance.showPrivacyOptionsForm(),
              ),
            const SizedBox(height: 20),
            _SectionLabel(s.accountSupportLegalSection),
            _SettingsTile(
              icon: Icons.bug_report_outlined,
              label: s.reportBug,
              onTap: () =>
                  Navigator.of(context)
                      .push(fadeSlideRoute((_) => const BugReportScreen())),
            ),
            _SettingsTile(
              icon: Icons.privacy_tip_outlined,
              label: s.privacyPolicy,
              onTap: () => _openUrl(_privacyPolicyUrl),
            ),
            _SettingsTile(
              icon: Icons.description_outlined,
              label: s.termsOfService,
              onTap: () => _openUrl(_termsOfServiceUrl),
            ),
          ],
        ),
      ),
    );
  }
}

/// Name/email summary at the top of Compte — tapping it opens [ProfileScreen]
/// where the actual editing, sign-out and delete-account controls live.
class _ProfileSummaryCard extends ConsumerWidget {
  const _ProfileSummaryCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    // myDisplayNameProvider (Firestore), not currentUser.displayName
    // (Firebase Auth) — see that provider's doc comment: Google Sign-In can
    // silently overwrite Firebase's copy on a later sign-in.
    final name =
        ref.watch(myDisplayNameProvider).value ?? currentUser.displayName ?? '';
    return PressableScale(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
          decoration: BoxDecoration(
            color: AppColors.of(context).card,
            border: Border.all(color: AppColors.of(context).line),
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppTextStyles.cardTitle(context)),
                    const SizedBox(height: 3),
                    Text(
                      currentUser.email ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.of(context).inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.of(context).inkSoft,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label, style: AppTextStyles.badge(context)),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.of(context).inkSoft),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: Icon(
        Icons.chevron_right,
        color: AppColors.of(context).inkSoft,
        size: 20,
      ),
      onTap: onTap,
    );
  }
}
