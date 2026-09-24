import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_strings.dart';
import '../models/meal.dart';
import '../providers/app_providers.dart';
import 'app_snackbar.dart';
import 'confirm_delete_dialog.dart';

/// Shared by every screen that lets an admin delete a meal (home's "Repas
/// récents" and the Repas tab) — confirms, deletes, then offers a few
/// seconds to undo via a snackbar. Kept in one place so the two call sites
/// can't drift apart the way they did before (home's delete had no undo
/// while the Repas tab's did).
Future<void> deleteMealWithUndo({
  required BuildContext context,
  required WidgetRef ref,
  required AppStrings s,
  required String babyId,
  required Meal meal,
}) async {
  final confirmed = await showConfirmDeleteDialog(
    context,
    title: s.deleteMealTitle,
    message: s.deleteMealMessage,
  );
  if (!confirmed) return;
  final mealRepo = ref.read(mealRepositoryProvider);
  await mealRepo.deleteMeal(babyId, meal.id);
  if (!context.mounted) return;
  // A "doigt qui glisse" tap on delete shouldn't cost a family its only
  // record of e.g. baby's first taste of spinach — give a few seconds to
  // undo before the deletion is truly final.
  AppSnackBar.showAction(
    context,
    s.mealDeletedUndo,
    duration: const Duration(seconds: 6),
    actionLabel: s.undo,
    onAction: () async {
      try {
        await mealRepo.addMeal(meal);
      } catch (_) {
        if (context.mounted) {
          AppSnackBar.showError(context, s.mealRestoreFailed);
        }
      }
    },
  );
}
