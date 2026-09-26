import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_strings.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/app_loading_indicator.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/pressable_scale.dart';

const _bugReportEmail = 'contact@nibblenibble.app';

/// A simple in-app form instead of jumping straight to a bare mailto: link
/// — lets the reporter see/adjust their contact email and actually write
/// the description before their mail app opens, rather than typing
/// everything from scratch in an external app.
class BugReportScreen extends ConsumerStatefulWidget {
  const BugReportScreen({super.key});

  @override
  ConsumerState<BugReportScreen> createState() => _BugReportScreenState();
}

class _BugReportScreenState extends ConsumerState<BugReportScreen> {
  late final TextEditingController _emailController;
  final _descriptionController = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(
      text: ref.read(currentUserProvider).email ?? '',
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<String> _buildReportBody(AppStrings s) async {
    final info = await PackageInfo.fromPlatform();
    final replyEmail = _emailController.text.trim();
    return '${_descriptionController.text.trim()}\n\n'
        '---\n'
        '${s.bugReportEmailLabel}: $replyEmail\n'
        'nibblenibble ${info.version} (${info.buildNumber})';
  }

  bool _validate(AppStrings s) {
    if (_descriptionController.text.trim().isEmpty) {
      AppSnackBar.showError(context, s.bugReportEmptyDescription);
      return false;
    }
    return true;
  }

  Future<void> _send() async {
    final s = AppStrings.of(context);
    if (!_validate(s)) return;
    setState(() => _sending = true);
    try {
      final body = await _buildReportBody(s);
      final uri = Uri(
        scheme: 'mailto',
        path: _bugReportEmail,
        query: Uri(
          queryParameters: {'subject': s.bugReportSubject, 'body': body},
        ).query,
      );
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pop();
      } else {
        // No mail app registered to handle mailto: (common on a fresh
        // device/emulator, or a phone with no mail client configured at
        // all) — rather than a dead-end error, copy the report so nothing
        // the user wrote is lost.
        await Clipboard.setData(ClipboardData(text: body));
        if (!mounted) return;
        AppSnackBar.showError(context, s.bugReportNoMailApp);
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _copyInstead() async {
    final s = AppStrings.of(context);
    if (!_validate(s)) return;
    try {
      final body = await _buildReportBody(s);
      await Clipboard.setData(ClipboardData(text: body));
      if (!mounted) return;
      AppSnackBar.showSuccess(context, s.bugReportCopied);
    } catch (_) {
      if (mounted) AppSnackBar.showError(context, s.genericErrorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(title: Text(s.reportBug)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(s.bugReportBodyIntro),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: s.bugReportEmailLabel),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _descriptionController,
              maxLines: 8,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: s.bugReportDescriptionLabel,
                hintText: s.bugReportDescriptionHint,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            PressableScale(
              child: ElevatedButton.icon(
                onPressed: _sending ? null : _send,
                icon: _sending
                    ? AppLoadingIndicator(size: 16, color: AppColors.of(context).onPrimary)
                    : const Icon(Icons.send, size: 18),
                label: Text(s.bugReportSend),
              ),
            ),
            const SizedBox(height: 10),
            PressableScale(
              child: TextButton.icon(
                onPressed: _sending ? null : _copyInstead,
                icon: const Icon(Icons.copy_outlined, size: 18),
                label: Text(s.bugReportCopyInstead),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
