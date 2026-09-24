import '../models/meal.dart';
import '../models/reaction.dart';

/// Aggregates over a list of *past* meals — shared by Stats and the PDF
/// export so the definition of "tried" (appeared in a past meal, reaction
/// recorded or not) and the per-reaction counts can't drift between the two.
class MealStats {
  const MealStats({required this.triedFoodIds, required this.reactionCounts});

  final Set<String> triedFoodIds;
  final Map<Reaction, int> reactionCounts;
}

MealStats computeMealStats(Iterable<Meal> pastMeals) {
  final triedFoodIds = <String>{};
  final reactionCounts = <Reaction, int>{};
  for (final meal in pastMeals) {
    for (final entry in meal.foods) {
      triedFoodIds.add(entry.foodId);
      if (entry.reaction != null) {
        reactionCounts[entry.reaction!] =
            (reactionCounts[entry.reaction!] ?? 0) + 1;
      }
    }
  }
  return MealStats(triedFoodIds: triedFoodIds, reactionCounts: reactionCounts);
}
