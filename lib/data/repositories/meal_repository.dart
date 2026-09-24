import '../../models/meal.dart';

abstract class MealRepository {
  Stream<List<Meal>> watchMeals(String babyId);

  /// Returns the newly created meal's id — needed to key a scheduled local
  /// notification so it can be cancelled later if the meal is edited/deleted.
  Future<String> addMeal(Meal meal);
  Future<void> updateMeal(Meal meal);
  Future<void> deleteMeal(String babyId, String mealId);
}
