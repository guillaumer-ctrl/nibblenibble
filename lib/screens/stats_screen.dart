import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_strings.dart';
import '../models/food.dart';
import '../models/reaction.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../utils/meal_stats.dart';
import '../widgets/animated_accordion.dart';
import '../widgets/app_loading_indicator.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/error_retry_view.dart';
import '../widgets/reaction_face_icon.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  // Which reaction rows are expanded to show their food list — collapsed by
  // default so the screen stays a quick glance, not a wall of chips.
  final Set<Reaction> _expandedReactions = {};

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final baby = ref.watch(selectedBabyProvider);
    final mealsAsync = ref.watch(mealsForSelectedBabyProvider);
    final foodsById = ref.watch(foodsByIdProvider);
    // The food's *current* reaction (latest recorded), one per food — not
    // the same as reactionCounts below, which tallies every reaction ever
    // logged (so a food re-reacted to twice counts twice there). For "which
    // foods are in this bucket", only the current status makes sense — a
    // food can't be both liked and disliked at once.
    final currentReactions = ref.watch(foodReactionsProvider);

    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(title: Text(s.statistics)),
      body: SafeArea(
        child: mealsAsync.when(
          data: (meals) {
            final pastMeals = meals.where((m) => m.isPast).toList();
            final stats = computeMealStats(pastMeals);
            final triedFoodIds = stats.triedFoodIds;
            final reactionCounts = stats.reactionCounts;
            final totalReactions = reactionCounts.values.fold(
              0,
              (a, b) => a + b,
            );
            final foodsByReaction = <Reaction, List<Food>>{};
            for (final entry in currentReactions.entries) {
              final food = foodsById[entry.key];
              if (food == null) continue;
              foodsByReaction.putIfAbsent(entry.value, () => []).add(food);
            }
            for (final foods in foodsByReaction.values) {
              foods.sort(
                (a, b) =>
                    a.displayName(context).compareTo(b.displayName(context)),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        value: '${triedFoodIds.length}',
                        label: s.foodsTried,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatTile(
                        value: baby?.diversificationDays?.toString() ?? '—',
                        label: s.diversificationDaysLabel,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text(
                  s.reactions,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                if (totalReactions == 0)
                  Text(
                    s.noReactionsYet,
                    style: TextStyle(color: AppColors.of(context).inkSoft),
                  )
                else
                  ...Reaction.values.map((r) {
                    final count = reactionCounts[r] ?? 0;
                    final foods = foodsByReaction[r] ?? const <Food>[];
                    final expanded = _expandedReactions.contains(r);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AnimatedAccordion(
                        expanded: expanded,
                        header: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: foods.isEmpty
                                  ? null
                                  : () => setState(() {
                                      if (expanded) {
                                        _expandedReactions.remove(r);
                                      } else {
                                        _expandedReactions.add(r);
                                      }
                                    }),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      ReactionFaceIcon(
                                        reaction: r,
                                        color: r.color(context),
                                        size: 18,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        r.label(context),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        '$count',
                                        style: TextStyle(
                                          color: AppColors.of(context).inkSoft,
                                        ),
                                      ),
                                      if (foods.isNotEmpty)
                                        AnimatedAccordionChevron(
                                          expanded: expanded,
                                          color: AppColors.of(context).inkSoft,
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: foods
                                .map(
                                  (f) => Chip(
                                    label: Text(f.displayName(context)),
                                    visualDensity: VisualDensity.compact,
                                    backgroundColor: r
                                        .tint(context)
                                        .withValues(alpha: 0.28),
                                    side: BorderSide(
                                      color: r
                                          .tint(context)
                                          .withValues(alpha: 0.85),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 28),
                Text(
                  s.foodsTriedSectionTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                if (triedFoodIds.isEmpty)
                  Text(
                    s.nothingToShowYet,
                    style: TextStyle(color: AppColors.of(context).inkSoft),
                  )
                else
                  ...() {
                    final byCategory = <FoodCategory, List<Food>>{};
                    for (final id in triedFoodIds) {
                      final food = foodsById[id];
                      if (food == null) continue;
                      byCategory.putIfAbsent(food.category, () => []).add(food);
                    }
                    return FoodCategory.values
                        .where((c) => byCategory.containsKey(c))
                        .map((category) {
                          final foods = byCategory[category]!
                            ..sort(
                              (a, b) => a
                                  .displayName(context)
                                  .compareTo(b.displayName(context)),
                            );
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  category.label(context),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12.5,
                                    color: AppColors.of(context).inkSoft,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  // Same Chip style as the expandable food
                                  // list under each reaction above — keeps
                                  // this section visually consistent with
                                  // "Réactions" instead of its own look, and
                                  // (unlike FoodBlock) never shows a
                                  // reaction icon here, just the tint.
                                  children: foods.map((f) {
                                    final reaction = currentReactions[f.id];
                                    return Chip(
                                      label: Text(f.displayName(context)),
                                      visualDensity: VisualDensity.compact,
                                      backgroundColor: reaction != null
                                          ? reaction
                                                .tint(context)
                                                .withValues(alpha: 0.28)
                                          : AppColors.of(context).primaryLight,
                                      side: BorderSide(
                                        color: reaction != null
                                            ? reaction
                                                  .tint(context)
                                                  .withValues(alpha: 0.85)
                                            : AppColors.of(context).line,
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          );
                        })
                        .toList();
                  }(),
                const SizedBox(height: 8),
                const BannerAdWidget(
                  androidAdUnitId: statsBannerAdUnitIdAndroid,
                ),
              ],
            );
          },
          loading: () => AppLoadingIndicator.center(),
          error: (_, _) => ErrorRetryView(
            onRetry: () => ref.invalidate(mealsForSelectedBabyProvider),
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.of(context).card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.of(context).line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(color: AppColors.of(context).primary),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.of(context).inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}
