import 'package:flutter_test/flutter_test.dart';
import 'package:nibblenibble/models/meal.dart';
import 'package:nibblenibble/models/reaction.dart';

void main() {
  group('Meal.isPast', () {
    test('is true for a meal logged in the past', () {
      final meal = Meal(
        id: '1',
        babyId: 'baby-1',
        dateTime: DateTime.now().subtract(const Duration(hours: 1)),
        foods: const [],
      );
      expect(meal.isPast, isTrue);
    });

    test('is false for a meal planned in the future', () {
      final meal = Meal(
        id: '1',
        babyId: 'baby-1',
        dateTime: DateTime.now().add(const Duration(hours: 1)),
        foods: const [],
      );
      expect(meal.isPast, isFalse);
    });
  });

  group('MealFoodEntry.copyWith', () {
    test('overrides only the given fields', () {
      const entry = MealFoodEntry(foodId: 'food-1');
      final updated = entry.copyWith(reaction: Reaction.aime, note: 'Miam');
      expect(updated.foodId, 'food-1');
      expect(updated.reaction, Reaction.aime);
      expect(updated.note, 'Miam');
    });

    test('keeps existing values when nothing is passed', () {
      const entry = MealFoodEntry(
        foodId: 'food-1',
        reaction: Reaction.aime,
        note: 'Miam',
      );
      final updated = entry.copyWith();
      expect(updated.reaction, Reaction.aime);
      expect(updated.note, 'Miam');
    });
  });
}
