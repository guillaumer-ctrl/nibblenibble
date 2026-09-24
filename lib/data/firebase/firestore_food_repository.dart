import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/food.dart';
import '../repositories/food_repository.dart';
import 'firestore_instance.dart';

FoodCategory _categoryFromString(String value) => FoodCategory.values
    .firstWhere((c) => c.name == value, orElse: () => FoodCategory.autre);

/// Reads the shared food database from Firestore (imported via
/// scripts/import_foods.py). Wired up in app_providers.dart.
class FirestoreFoodRepository implements FoodRepository {
  FirestoreFoodRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? appFirestore;

  final FirebaseFirestore _db;

  @override
  Future<List<Food>> getAllFoods() async {
    final snap = await _db.collection('foods').get();
    return snap.docs
        .map(
          (d) => Food(
            id: d.id,
            name: d.data()['name'] as String,
            category: _categoryFromString(d.data()['category'] as String),
            nameEn: d.data()['nameEn'] as String?,
            nameEs: d.data()['nameEs'] as String?,
          ),
        )
        .toList();
  }

  @override
  Future<Food?> getFood(String id) async {
    final doc = await _db.collection('foods').doc(id).get();
    if (!doc.exists) return null;
    return Food(
      id: doc.id,
      name: doc.data()!['name'] as String,
      category: _categoryFromString(doc.data()!['category'] as String),
      nameEn: doc.data()!['nameEn'] as String?,
      nameEs: doc.data()!['nameEs'] as String?,
    );
  }

  CollectionReference<Map<String, dynamic>> _customFoodsOf(String babyId) =>
      _db.collection('babies').doc(babyId).collection('customFoods');

  @override
  Stream<List<Food>> watchCustomFoods(String babyId) => _customFoodsOf(
    babyId,
  ).orderBy('name').snapshots().map(
    (snap) => snap.docs
        .map(
          (d) => Food(
            id: d.id,
            name: d.data()['name'] as String,
            category: _categoryFromString(d.data()['category'] as String),
          ),
        )
        .toList(),
  );

  @override
  Future<Food> addCustomFood(
    String babyId,
    String name,
    FoodCategory category,
  ) async {
    final ref = await _customFoodsOf(babyId).add({
      'name': name,
      'category': category.name,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return Food(id: ref.id, name: name, category: category);
  }
}
