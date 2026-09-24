import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../l10n/app_strings.dart';
import '../models/baby_profile.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/app_loading_indicator.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/confirm_delete_dialog.dart';
import '../widgets/pressable_scale.dart';

class BabyProfileScreen extends ConsumerStatefulWidget {
  const BabyProfileScreen({super.key, required this.baby});

  final BabyProfile baby;

  @override
  ConsumerState<BabyProfileScreen> createState() => _BabyProfileScreenState();
}

class _BabyProfileScreenState extends ConsumerState<BabyProfileScreen> {
  late final TextEditingController _nameController;
  late DateTime _birthDate;
  late DateTime? _diversificationStartDate;
  late BabyGender _gender;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.baby.name);
    _birthDate = widget.baby.birthDate;
    _diversificationStartDate = widget.baby.diversificationStartDate;
    _gender = widget.baby.gender;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      locale: AppStrings.of(context).datePickerLocale,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _pickDiversificationStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _diversificationStartDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      locale: AppStrings.of(context).datePickerLocale,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (picked != null) {
      setState(() => _diversificationStartDate = picked);
    }
  }

  Future<void> _save() async {
    final canEdit = ref.read(isCurrentUserAdminProvider);
    if (!canEdit) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(babyRepositoryProvider)
          .updateBaby(
            BabyProfile(
              id: widget.baby.id,
              name: _nameController.text.trim(),
              birthDate: _birthDate,
              diversificationStartDate: _diversificationStartDate,
              gender: _gender,
            ),
          );
      if (mounted) {
        AppSnackBar.showSuccess(context, AppStrings.of(context).profileUpdated);
      }
    } catch (_) {
      if (mounted) {
        AppSnackBar.showError(context, AppStrings.of(context).profileUpdateFailed);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteBaby() async {
    final s = AppStrings.of(context);
    final confirmed = await showTypeToConfirmDeleteDialog(
      context,
      title: s.deleteBabyTitle(widget.baby.name),
      message: s.deleteBabyMessage,
      nameToType: widget.baby.name,
    );
    if (!confirmed || !mounted) return;

    // `showDialog`'s Future resolves the instant the dialog is popped, not
    // once its exit transition finishes — popping *this* screen right away
    // starts a second Navigator transition while the dialog's is still
    // playing on the same Overlay. That overlap is what was corrupting the
    // Overlay's element tree (Crashlytics: duplicate GlobalKeys on
    // _OverlayEntryWidgetState, and a PressableScale button's ScaleTransition
    // left dangling mid-animation). Letting the dialog's transition finish
    // first avoids the two ever overlapping.
    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;

    // Grab a container that outlives this screen, then pop *before* touching
    // any provider. Home, Repas, Stats and Compte are all kept alive at once
    // (IndexedStack in RootShell) and rebuild the moment selectedBabyIdProvider
    // or babiesProvider changes; doing that rebuild in the same frame as this
    // screen's own teardown is what was tripping Flutter's
    // '_dependents.isEmpty' assertion. Popping first, then mutating providers
    // from a container that isn't tied to this widget, keeps the two
    // completely out of each other's way instead of racing to avoid overlap.
    final container = ProviderScope.containerOf(context, listen: false);
    final babyId = widget.baby.id;
    final failedMessage = s.deleteBabyFailed;
    Navigator.of(context).pop();
    unawaited(_finishDeletingBaby(container, babyId, failedMessage));
  }

  static Future<void> _finishDeletingBaby(
    ProviderContainer container,
    String babyId,
    String failedMessage,
  ) async {
    try {
      final remaining = (container.read(babiesProvider).value ?? const [])
          .where((b) => b.id != babyId)
          .toList();
      container.read(selectedBabyIdProvider.notifier).state = remaining.isEmpty
          ? null
          : remaining.first.id;
      // No manual invalidate: watchBabies() already reacts to the user
      // doc's own `babyIds` field (which deleteBaby updates via
      // arrayRemove), so the existing listener updates on its own —
      // invalidating here only forced a full resubscribe, which is what
      // was triggering a brief spurious PERMISSION_DENIED from a known
      // Firestore SDK issue on freshly (re)opened listeners.
      await container.read(babyRepositoryProvider).deleteBaby(babyId);
    } catch (_) {
      // No BuildContext here (this runs after the screen has already been
      // popped) — see AppSnackBar.showErrorNoContext's doc comment.
      AppSnackBar.showErrorNoContext(failedMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final canEdit = ref.watch(isCurrentUserAdminProvider);

    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(title: Text(s.babyProfile)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextField(
              controller: _nameController,
              enabled: canEdit,
              decoration: InputDecoration(labelText: s.firstName),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: canEdit ? _pickBirthDate : null,
              child: InputDecorator(
                decoration: InputDecoration(labelText: s.birthDate),
                child: Text(
                  DateFormat(
                    s.dateOnlyPattern,
                    s.intlLocale,
                  ).format(_birthDate),
                ),
              ),
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: canEdit ? _pickDiversificationStartDate : null,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: s.diversificationStartDateLabel,
                  suffixIcon: canEdit && _diversificationStartDate != null
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          tooltip: s.clearDate,
                          onPressed: () =>
                              setState(() => _diversificationStartDate = null),
                        )
                      : null,
                ),
                child: Text(
                  _diversificationStartDate == null
                      ? s.notSet
                      : DateFormat(
                          s.dateOnlyPattern,
                          s.intlLocale,
                        ).format(_diversificationStartDate!),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              s.sex,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppColors.of(context).inkSoft),
            ),
            const SizedBox(height: 8),
            Row(
              children: BabyGender.values.map((g) {
                final selected = _gender == g;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: g == BabyGender.values.last ? 0 : 8,
                    ),
                    child: PressableScale(
                      child: ChoiceChip(
                        label: Text(g.label(context)),
                        selected: selected,
                        selectedColor: AppColors.of(context).sage
                            .withValues(alpha: 0.3),
                        checkmarkColor: AppColors.of(context).sageDark,
                        labelStyle: TextStyle(
                          color: selected
                              ? AppColors.of(context).sageDark
                              : AppColors.of(context).ink,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.normal,
                        ),
                        onSelected: canEdit
                            ? (_) => setState(() => _gender = g)
                            : null,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            if (canEdit) ...[
              const SizedBox(height: 24),
              PressableScale(
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? AppLoadingIndicator(size: 18, color: AppColors.of(context).onPrimary)
                      : Text(s.save),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: PressableScale(
                  child: TextButton(
                    onPressed: _deleteBaby,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.of(context).red,
                    ),
                    child: Text(s.deleteThisBaby),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
