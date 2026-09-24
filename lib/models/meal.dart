import 'reaction.dart';

/// One food served during a meal, with the baby's reaction and an optional note.
class MealFoodEntry {
  const MealFoodEntry({
    required this.foodId,
    this.reaction,
    this.note,
  });

  final String foodId;

  /// Null for an upcoming (not-yet-happened) meal.
  final Reaction? reaction;
  final String? note;

  MealFoodEntry copyWith({Reaction? reaction, String? note}) => MealFoodEntry(
    foodId: foodId,
    reaction: reaction ?? this.reaction,
    note: note ?? this.note,
  );
}

/// A logged or planned meal for a baby. Past meals have reactions recorded;
/// upcoming meals list the planned foods without reactions yet.
class Meal {
  const Meal({
    required this.id,
    required this.babyId,
    required this.dateTime,
    required this.foods,
    this.loggedByMemberId,
  });

  final String id;
  final String babyId;
  final DateTime dateTime;
  final List<MealFoodEntry> foods;

  /// Which family member logged/edited this meal, for accountability.
  final String? loggedByMemberId;

  bool get isPast => dateTime.isBefore(DateTime.now());
}
