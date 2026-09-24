import '../../models/food.dart';

abstract class FoodRepository {
  /// The shared, global food database — read-only, common to every family.
  Future<List<Food>> getAllFoods();
  Future<Food?> getFood(String id);

  /// Foods a specific family added themselves because they weren't in the
  /// shared database — scoped to one baby (not shared globally) so one
  /// family's additions never pollute another's search results.
  Stream<List<Food>> watchCustomFoods(String babyId);
  Future<Food> addCustomFood(
    String babyId,
    String name,
    FoodCategory category,
  );
}
