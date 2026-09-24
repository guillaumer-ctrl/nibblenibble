import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_strings.dart';
import '../models/food.dart';
import '../models/meal.dart';
import '../motion/slide_up_route.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../utils/diacritics.dart';
import '../widgets/animated_removal_list.dart';
import '../widgets/app_loading_indicator.dart';
import '../widgets/error_retry_view.dart';
import '../widgets/meal_card.dart';
import '../widgets/meal_delete_with_undo.dart';
import 'meal_form_screen.dart';

/// Combines the mockup's "Repas à venir" (06) and "Repas passés" (07)
/// screens under one nav tab with a switcher, instead of two separate
/// bottom-nav slots.
class MealsScreen extends StatefulWidget {
  const MealsScreen({super.key});

  @override
  State<MealsScreen> createState() => _MealsScreenState();
}

class _MealsScreenState extends State<MealsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(
        title: Text(s.navMeals),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.of(context).primary,
          unselectedLabelColor: AppColors.of(context).inkSoft,
          indicatorColor: AppColors.of(context).primary,
          tabs: [Tab(text: s.upcoming), Tab(text: s.past)],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _MealsList(upcoming: true),
          _MealsList(upcoming: false),
        ],
      ),
    );
  }
}

class _MealsList extends ConsumerStatefulWidget {
  const _MealsList({required this.upcoming});

  final bool upcoming;

  @override
  ConsumerState<_MealsList> createState() => _MealsListState();
}

class _MealsListState extends ConsumerState<_MealsList> {
  String _search = '';

  bool _matchesSearch(Meal meal, Map<String, Food> foodsById) {
    if (_search.isEmpty) return true;
    for (final f in meal.foods) {
      final food = foodsById[f.foodId];
      final name = food == null ? '' : food.displayNameFor(AppStrings.of(context));
      if (foldDiacritics(name.toLowerCase()).contains(_search)) return true;
      final note = f.note ?? '';
      if (foldDiacritics(note.toLowerCase()).contains(_search)) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final baby = ref.watch(selectedBabyProvider);
    final mealsAsync = ref.watch(mealsForSelectedBabyProvider);
    final canEdit = ref.watch(isCurrentUserAdminProvider);
    final foodsById = ref.watch(foodsByIdProvider);

    return SafeArea(
      child: mealsAsync.when(
        data: (meals) {
          var filtered = meals.where((m) => m.isPast != widget.upcoming).toList();
          if (widget.upcoming) {
            filtered.sort((a, b) => a.dateTime.compareTo(b.dateTime));
          } else {
            filtered.sort((a, b) => b.dateTime.compareTo(a.dateTime));
          }
          final beforeSearch = filtered;
          if (!widget.upcoming) {
            filtered = filtered.where((m) => _matchesSearch(m, foodsById)).toList();
          }
          if (beforeSearch.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                widget.upcoming ? s.noUpcomingMeals : s.noMealsRecorded,
              ),
            );
          }
          return Column(
            children: [
              if (!widget.upcoming)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: TextField(
                    onChanged: (v) =>
                        setState(() => _search = foldDiacritics(v.toLowerCase())),
                    decoration: InputDecoration(
                      hintText: s.searchPastMealsHint,
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                    ),
                    textAlignVertical: TextAlignVertical.center,
                  ),
                ),
              Expanded(
                child: filtered.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          s.noMealsMatchSearch,
                        ),
                      )
                    : AnimatedDiffList<Meal>(
                        // 10 = MealCard's bottom margin, so the gap under the
                        // search bar matches the gap between cards.
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                        items: filtered,
                        keyOf: (meal) => meal.id,
                        itemBuilder: (context, meal) => MealCard(
                          meal: meal,
                          canEdit: canEdit,
                          onTap: () => Navigator.of(context).push(
                            slideUpRoute(
                              (_) => MealFormScreen(
                                babyId: baby!.id,
                                existingMeal: meal,
                              ),
                            ),
                          ),
                          onDelete: () => deleteMealWithUndo(
                            context: context,
                            ref: ref,
                            s: s,
                            babyId: baby!.id,
                            meal: meal,
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
        loading: () => AppLoadingIndicator.center(),
        error: (_, _) => ErrorRetryView(
          onRetry: () => ref.invalidate(mealsForSelectedBabyProvider),
        ),
      ),
    );
  }
}
