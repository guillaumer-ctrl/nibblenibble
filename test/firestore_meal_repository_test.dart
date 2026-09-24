import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nibblenibble/data/firebase/firestore_meal_repository.dart';
import 'package:nibblenibble/models/meal.dart';
import 'package:nibblenibble/models/reaction.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FirestoreMealRepository repo;
  const babyId = 'baby-1';

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repo = FirestoreMealRepository(firestore: firestore);
  });

  test('addMeal writes fields and round-trips through watchMeals', () async {
    final id = await repo.addMeal(
      Meal(
        id: '',
        babyId: babyId,
        dateTime: DateTime(2026, 1, 15, 8, 30),
        foods: const [
          MealFoodEntry(foodId: 'food-1', reaction: Reaction.aime, note: 'Miam'),
        ],
        loggedByMemberId: 'member-1',
      ),
    );

    final meals = await repo.watchMeals(babyId).first;
    expect(meals, hasLength(1));
    expect(meals.first.id, id);
    expect(meals.first.foods.single.reaction, Reaction.aime);
    expect(meals.first.foods.single.note, 'Miam');
    expect(meals.first.loggedByMemberId, 'member-1');
  });

  test('updateMeal overwrites the existing doc rather than creating a new one', () async {
    final id = await repo.addMeal(
      Meal(
        id: '',
        babyId: babyId,
        dateTime: DateTime(2026, 1, 15),
        foods: const [MealFoodEntry(foodId: 'food-1')],
      ),
    );

    await repo.updateMeal(
      Meal(
        id: id,
        babyId: babyId,
        dateTime: DateTime(2026, 1, 15),
        foods: const [
          MealFoodEntry(foodId: 'food-1', reaction: Reaction.pasAime),
        ],
      ),
    );

    final meals = await repo.watchMeals(babyId).first;
    expect(meals, hasLength(1));
    expect(meals.single.foods.single.reaction, Reaction.pasAime);
  });

  test('deleteMeal removes the doc', () async {
    final id = await repo.addMeal(
      Meal(
        id: '',
        babyId: babyId,
        dateTime: DateTime(2026, 1, 15),
        foods: const [MealFoodEntry(foodId: 'food-1')],
      ),
    );

    await repo.deleteMeal(babyId, id);

    final meals = await repo.watchMeals(babyId).first;
    expect(meals, isEmpty);
  });

  test('watchMeals only returns meals for the given baby', () async {
    await repo.addMeal(
      Meal(
        id: '',
        babyId: babyId,
        dateTime: DateTime(2026, 1, 15),
        foods: const [MealFoodEntry(foodId: 'food-1')],
      ),
    );
    final otherRepo = FirestoreMealRepository(firestore: firestore);
    await otherRepo.addMeal(
      Meal(
        id: '',
        babyId: 'baby-2',
        dateTime: DateTime(2026, 1, 15),
        foods: const [MealFoodEntry(foodId: 'food-2')],
      ),
    );

    final meals = await repo.watchMeals(babyId).first;
    expect(meals, hasLength(1));
    expect(meals.single.foods.single.foodId, 'food-1');
  });
}
