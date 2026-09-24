import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../l10n/app_strings.dart';
import '../models/baby_profile.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/app_loading_indicator.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/pressable_scale.dart';
import 'family_screen.dart';

class AddBabyScreen extends ConsumerStatefulWidget {
  const AddBabyScreen({super.key, this.onboarding = false});

  /// True when reached as step 2 of sign-up — successfully creating the
  /// baby then continues to step 3 (invite the family) instead of just
  /// popping back to an empty home screen.
  final bool onboarding;

  @override
  ConsumerState<AddBabyScreen> createState() => _AddBabyScreenState();
}

class _AddBabyScreenState extends ConsumerState<AddBabyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  DateTime? _birthDate;
  BabyGender _gender = BabyGender.nonPrecise;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year, now.month - 6, now.day),
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      locale: AppStrings.of(context).datePickerLocale,
      // Calendar only: the manual-entry keyboard field doesn't offer "/" on
      // some Android keyboards, making the date impossible to type.
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _birthDate == null) {
      if (_birthDate == null) {
        AppSnackBar.show(context, AppStrings.of(context).chooseBirthDate);
      }
      return;
    }
    setState(() => _loading = true);
    try {
      final newBabyId = await ref
          .read(babyRepositoryProvider)
          .addBaby(
            BabyProfile(
              id: '', // ignored on create — Firestore assigns the id
              name: _nameController.text.trim(),
              birthDate: _birthDate!,
              gender: _gender,
            ),
          );
      if (!mounted) return;
      // babiesProvider's underlying stream (user doc -> whereIn query) can
      // lag behind its own just-committed write — the new baby was only
      // ever reliably showing up after a full app restart, i.e. after a
      // brand new subscription was created. Invalidating here forces that
      // same fresh subscription immediately instead of waiting on the old
      // one to notice.
      ref.invalidate(babiesProvider);
      // Without this, adding a baby beyond the first one leaves the
      // previously selected baby active — the new one exists but never
      // shows up on screen until picked manually from the switcher.
      ref.read(selectedBabyIdProvider.notifier).state = newBabyId;
      if (widget.onboarding) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const FamilyScreen(onboarding: true),
          ),
        );
      } else {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        AppSnackBar.showError(context, AppStrings.of(context).createProfileFailed);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(title: Text(s.addBaby)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: s.firstName),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? s.required : null,
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: _pickBirthDate,
                  child: InputDecorator(
                    decoration: InputDecoration(labelText: s.birthDate),
                    child: Text(
                      _birthDate == null
                          ? s.chooseADate
                          : DateFormat(
                              s.dateOnlyPattern,
                              s.intlLocale,
                            ).format(_birthDate!),
                      style: TextStyle(
                        color: _birthDate == null
                            ? AppColors.of(context).inkSoft
                            : AppColors.of(context).ink,
                      ),
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
                            onSelected: (_) => setState(() => _gender = g),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                PressableScale(
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? AppLoadingIndicator(size: 18, color: AppColors.of(context).onPrimary)
                        : Text(
                            widget.onboarding
                                ? s.continueLabel
                                : s.createProfile,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
