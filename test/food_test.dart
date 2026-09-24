import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nibblenibble/l10n/app_strings.dart';
import 'package:nibblenibble/models/food.dart';

void main() {
  const french = AppStrings(Locale('fr', 'FR'));
  const english = AppStrings(Locale('en', 'US'));

  group('Food.displayNameFor', () {
    test('returns the French name in French', () {
      const food = Food(
        id: '1',
        name: 'Épinard',
        nameEn: 'Spinach',
        category: FoodCategory.legumes,
      );
      expect(food.displayNameFor(french), 'Épinard');
    });

    test('returns the English name in English', () {
      const food = Food(
        id: '1',
        name: 'Épinard',
        nameEn: 'Spinach',
        category: FoodCategory.legumes,
      );
      expect(food.displayNameFor(english), 'Spinach');
    });

    test('falls back to the French name in English when nameEn is missing', () {
      const food = Food(
        id: '1',
        name: 'Épinard',
        category: FoodCategory.legumes,
      );
      expect(food.displayNameFor(english), 'Épinard');
    });
  });
}
