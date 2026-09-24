import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nibblenibble/data/firebase/firestore_food_repository.dart';
import 'package:nibblenibble/models/food.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FirestoreFoodRepository repo;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repo = FirestoreFoodRepository(firestore: firestore);
  });

  test('getAllFoods reads the shared /foods collection', () async {
    await firestore.collection('foods').doc('food-1').set({
      'name': 'Épinard',
      'category': 'legumes',
      'nameEn': 'Spinach',
    });

    final foods = await repo.getAllFoods();
    expect(foods, hasLength(1));
    expect(foods.single.name, 'Épinard');
    expect(foods.single.category, FoodCategory.legumes);
    expect(foods.single.nameEn, 'Spinach');
  });

  test('addCustomFood writes under the baby and round-trips via watchCustomFoods', () async {
    final food = await repo.addCustomFood('baby-1', 'Courge butternut', FoodCategory.legumes);

    expect(food.name, 'Courge butternut');
    expect(food.category, FoodCategory.legumes);

    final customFoods = await repo.watchCustomFoods('baby-1').first;
    expect(customFoods, hasLength(1));
    expect(customFoods.single.id, food.id);
    expect(customFoods.single.name, 'Courge butternut');
    // Custom foods never have an English translation of their own.
    expect(customFoods.single.nameEn, isNull);
  });

  test('custom foods are scoped to one baby, never shared with another', () async {
    await repo.addCustomFood('baby-1', 'Courge butternut', FoodCategory.legumes);
    await repo.addCustomFood('baby-2', 'Riz complet', FoodCategory.feculents);

    final babyOneFoods = await repo.watchCustomFoods('baby-1').first;
    final babyTwoFoods = await repo.watchCustomFoods('baby-2').first;

    expect(babyOneFoods.map((f) => f.name), ['Courge butternut']);
    expect(babyTwoFoods.map((f) => f.name), ['Riz complet']);
  });

  test('custom foods never appear in the shared /foods collection', () async {
    await repo.addCustomFood('baby-1', 'Courge butternut', FoodCategory.legumes);

    final sharedFoods = await repo.getAllFoods();
    expect(sharedFoods, isEmpty);
  });
}
