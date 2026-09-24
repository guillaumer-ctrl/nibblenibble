import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/meal.dart';
import '../../models/reaction.dart';
import '../repositories/meal_repository.dart';
import 'firestore_instance.dart';

Reaction? _reactionFromString(String? value) {
  if (value == null) return null;
  return Reaction.values.firstWhere(
    (r) => r.name == value,
    orElse: () => Reaction.mitige,
  );
}

MealFoodEntry _entryFromMap(Map<String, dynamic> map) => MealFoodEntry(
  foodId: map['foodId'] as String,
  reaction: _reactionFromString(map['reaction'] as String?),
  note: map['note'] as String?,
);

Map<String, dynamic> _entryToMap(MealFoodEntry entry) => {
  'foodId': entry.foodId,
  'reaction': entry.reaction?.name,
  'note': entry.note,
};

Meal _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc, String babyId) {
  final data = doc.data()!;
  return Meal(
    id: doc.id,
    babyId: babyId,
    dateTime: (data['dateTime'] as Timestamp).toDate(),
    loggedByMemberId: data['loggedByMemberId'] as String?,
    note: data['note'] as String?,
    foods: (data['foods'] as List<dynamic>? ?? const [])
        .map((e) => _entryFromMap(Map<String, dynamic>.from(e as Map)))
        .toList(),
  );
}

class FirestoreMealRepository implements MealRepository {
  FirestoreMealRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? appFirestore;

  final FirebaseFirestore _db;

  // Bounds the live listener's document count (and therefore its Firestore
  // read cost and in-memory size) as a baby's meal history grows over years
  // of logging. Ordered by dateTime descending, so the cap only ever drops
  // the oldest meals — well past what a diversification-tracking app's
  // stats/search/export screens realistically need day to day.
  static const int _mealsLimit = 400;

  CollectionReference<Map<String, dynamic>> _mealsOf(String babyId) =>
      _db.collection('babies').doc(babyId).collection('meals');

  @override
  Stream<List<Meal>> watchMeals(String babyId) => _mealsOf(babyId)
      .orderBy('dateTime', descending: true)
      .limit(_mealsLimit)
      .snapshots()
      .map((snap) => snap.docs.map((d) => _fromDoc(d, babyId)).toList());

  @override
  Future<String> addMeal(Meal meal) async {
    final ref = await _mealsOf(meal.babyId).add({
      'dateTime': Timestamp.fromDate(meal.dateTime),
      'loggedByMemberId': meal.loggedByMemberId,
      'note': meal.note,
      'foods': meal.foods.map(_entryToMap).toList(),
    });
    return ref.id;
  }

  @override
  Future<void> updateMeal(Meal meal) async {
    await _mealsOf(meal.babyId).doc(meal.id).update({
      'dateTime': Timestamp.fromDate(meal.dateTime),
      'loggedByMemberId': meal.loggedByMemberId,
      'note': meal.note,
      'foods': meal.foods.map(_entryToMap).toList(),
    });
  }

  @override
  Future<void> deleteMeal(String babyId, String mealId) async {
    await _mealsOf(babyId).doc(mealId).delete();
  }
}
