import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../l10n/app_strings.dart';
import '../models/meal.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import 'food_block.dart';

class MealCard extends ConsumerWidget {
  const MealCard({
    super.key,
    required this.meal,
    this.onTap,
    this.onDelete,
    this.canEdit = false,
  });

  final Meal meal;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool canEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final foodsById = ref.watch(foodsByIdProvider);
    final foodReactions = ref.watch(foodReactionsProvider);
    final membersById = ref.watch(familyMembersByIdProvider);
    final loggedByName = membersById[meal.loggedByMemberId]?.name;
    final s = AppStrings.of(context);
    final dateLabel = DateFormat(
      s.dateTimePattern,
      s.intlLocale,
    ).format(meal.dateTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.line),
      ),
      child: InkWell(
        // Always tappable, even read-only: a read-only member can't change
        // the meal's date/foods but can still add the baby's reaction, so
        // opening the form is legitimate regardless of canEdit.
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      dateLabel[0].toUpperCase() + dateLabel.substring(1),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: colors.ink,
                      ),
                    ),
                  ),
                  if (canEdit && onDelete != null)
                    Tooltip(
                      message: s.deleteMealTooltip,
                      child: InkWell(
                        onTap: onDelete,
                        child: Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: colors.inkSoft,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Container(height: 1, color: colors.line),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: meal.foods.map((entry) {
                  final name =
                      foodsById[entry.foodId]?.displayName(context) ??
                      entry.foodId;
                  // A food only ever has one current reaction — if this
                  // particular meal instance didn't record one, fall back to
                  // whatever was last recorded for that food elsewhere.
                  final reaction =
                      entry.reaction ?? foodReactions[entry.foodId];
                  final note = (entry.note ?? '').trim();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FoodBlock(name: name, reaction: reaction, expand: false),
                      if (note.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 3, 10, 0),
                          child: Text(
                            note,
                            style: TextStyle(fontSize: 12, color: colors.inkSoft),
                          ),
                        ),
                    ],
                  );
                }).toList(),
              ),
              if ((meal.note ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  meal.note!.trim(),
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: colors.inkSoft,
                  ),
                ),
              ],
              if (loggedByName != null) ...[
                const SizedBox(height: 8),
                Text(
                  s.loggedBy(loggedByName),
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.inkSoft,
                    fontStyle: FontStyle.italic,
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
