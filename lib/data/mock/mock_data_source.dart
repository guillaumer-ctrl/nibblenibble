import 'dart:async';

import '../../models/baby_profile.dart';
import '../../models/family_invitation.dart';
import '../../models/family_member.dart';
import '../../models/family_note.dart';
import '../../models/food.dart';
import '../../models/meal.dart';
import '../../models/reaction.dart';
import '../../models/user_role.dart';
import '../repositories/baby_repository.dart';
import '../repositories/family_repository.dart';
import '../repositories/food_repository.dart';
import '../repositories/meal_repository.dart';
import '../repositories/note_repository.dart';

/// Single in-memory store backing all four mock repositories, so they can
/// share and mutate the same sample dataset. Stands in for Firestore until
/// the Firebase project exists; swap the providers in app_providers.dart
/// for real implementations without touching UI code.
class MockDataStore {
  MockDataStore._() {
    _seed();
  }

  static final MockDataStore instance = MockDataStore._();

  final List<BabyProfile> _babies = [];
  final List<FamilyMember> _members = [];
  final List<FamilyInvitation> _invitations = [];
  final List<Food> _foods = [];
  final List<Meal> _meals = [];
  final List<FamilyNote> _notes = [];
  final Map<String, List<Food>> _customFoodsByBaby = {};

  final _babiesController = StreamController<List<BabyProfile>>.broadcast();
  final _membersController = StreamController<List<FamilyMember>>.broadcast();
  final _invitationsController =
      StreamController<List<FamilyInvitation>>.broadcast();
  final _mealsController = StreamController<List<Meal>>.broadcast();
  final _notesController = StreamController<List<FamilyNote>>.broadcast();
  final _customFoodsController =
      StreamController<Map<String, List<Food>>>.broadcast();

  void _seed() {
    _babies.addAll([
      BabyProfile(
        id: 'baby-lea',
        name: 'Léa',
        birthDate: DateTime.now().subtract(const Duration(days: 30 * 8)),
        diversificationStartDate:
            DateTime.now().subtract(const Duration(days: 51)),
      ),
      BabyProfile(
        id: 'baby-noe',
        name: 'Noé',
        birthDate: DateTime.now().subtract(const Duration(days: 30 * 3)),
      ),
    ]);

    _members.addAll(const [
      FamilyMember(
        id: 'member-camille',
        name: 'Camille',
        email: 'camille@example.com',
        role: UserRole.admin,
      ),
      FamilyMember(
        id: 'member-thomas',
        name: 'Thomas',
        email: 'thomas@example.com',
        role: UserRole.admin,
      ),
      FamilyMember(
        id: 'member-josette',
        name: 'Mamie Josette',
        email: 'josette@example.com',
        role: UserRole.readOnly,
      ),
    ]);

    _invitations.add(
      FamilyInvitation(
        id: 'invite-1',
        email: 'papi.michel@example.com',
        babyId: 'baby-lea',
        invitedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    );

    _foods.addAll(const [
      Food(
        id: 'food-carotte',
        name: 'Carotte',
        nameEn: 'Carrot',
        nameEs: 'Zanahoria',
        category: FoodCategory.legumes,
      ),
      Food(
        id: 'food-courgette',
        name: 'Courgette',
        nameEn: 'Zucchini',
        nameEs: 'Calabacín',
        category: FoodCategory.legumes,
      ),
      Food(
        id: 'food-pomme',
        name: 'Pomme',
        nameEn: 'Apple',
        nameEs: 'Manzana',
        category: FoodCategory.fruits,
      ),
      Food(
        id: 'food-banane',
        name: 'Banane',
        nameEn: 'Banana',
        nameEs: 'Plátano',
        category: FoodCategory.fruits,
      ),
      Food(
        id: 'food-riz',
        name: 'Riz',
        nameEn: 'Rice',
        nameEs: 'Arroz',
        category: FoodCategory.feculents,
      ),
      Food(
        id: 'food-poulet',
        name: 'Poulet',
        nameEn: 'Chicken',
        nameEs: 'Pollo',
        category: FoodCategory.viandes,
      ),
      Food(
        id: 'food-cabillaud',
        name: 'Cabillaud',
        nameEn: 'Cod',
        nameEs: 'Bacalao',
        category: FoodCategory.poissons,
      ),
    ]);

    _meals.addAll([
      Meal(
        id: 'meal-1',
        babyId: 'baby-lea',
        dateTime: DateTime.now().subtract(const Duration(days: 1)),
        loggedByMemberId: 'member-camille',
        foods: const [
          MealFoodEntry(foodId: 'food-carotte', reaction: Reaction.aime),
          MealFoodEntry(foodId: 'food-riz', reaction: Reaction.mitige),
        ],
      ),
      Meal(
        id: 'meal-2',
        babyId: 'baby-lea',
        dateTime: DateTime.now().subtract(const Duration(days: 3)),
        loggedByMemberId: 'member-thomas',
        foods: const [
          MealFoodEntry(
            foodId: 'food-courgette',
            reaction: Reaction.pasAime,
            note: 'A recraché, à retenter dans 2 semaines.',
          ),
        ],
      ),
      Meal(
        id: 'meal-3',
        babyId: 'baby-lea',
        dateTime: DateTime.now().add(const Duration(days: 1)),
        foods: const [
          MealFoodEntry(foodId: 'food-pomme'),
          MealFoodEntry(foodId: 'food-poulet'),
        ],
      ),
    ]);

    _notes.add(
      FamilyNote(
        id: 'note-1',
        text: 'On essaie les épinards cette semaine !',
        authorName: 'Camille',
        updatedAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
    );

    _emitAll();
  }

  void _emitAll() {
    _babiesController.add(List.unmodifiable(_babies));
    _membersController.add(List.unmodifiable(_members));
    _invitationsController.add(List.unmodifiable(_invitations));
    _mealsController.add(List.unmodifiable(_meals));
    _notesController.add(List.unmodifiable(_notes));
  }

  // Each watch* method replays the current snapshot to every new subscriber
  // before forwarding live updates — a plain broadcast stream only pushes to
  // whoever is already listening, so a screen built after `_seed()` ran would
  // otherwise see nothing until the next mutation.

  // --- Babies ---
  Stream<List<BabyProfile>> watchBabies() async* {
    yield List.unmodifiable(_babies);
    yield* _babiesController.stream;
  }

  BabyProfile? getBaby(String id) =>
      _babies.where((b) => b.id == id).firstOrNull;

  String addBaby(BabyProfile baby) {
    final withId = baby.id.isNotEmpty
        ? baby
        : BabyProfile(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            name: baby.name,
            birthDate: baby.birthDate,
            diversificationStartDate: baby.diversificationStartDate,
            gender: baby.gender,
          );
    _babies.add(withId);
    _emitAll();
    return withId.id;
  }

  void updateBaby(BabyProfile baby) {
    final index = _babies.indexWhere((b) => b.id == baby.id);
    if (index != -1) _babies[index] = baby;
    _emitAll();
  }

  void deleteBaby(String babyId) {
    _babies.removeWhere((b) => b.id == babyId);
    _meals.removeWhere((m) => m.babyId == babyId);
    _emitAll();
  }

  // --- Family ---
  Stream<List<FamilyMember>> watchMembers() async* {
    yield List.unmodifiable(_members);
    yield* _membersController.stream;
  }

  Stream<List<FamilyInvitation>> watchInvitations() async* {
    yield List.unmodifiable(_invitations);
    yield* _invitationsController.stream;
  }

  void invite(String babyId, String email, UserRole role) {
    _invitations.add(
      FamilyInvitation(
        id: 'invite-${_invitations.length + 1}',
        email: email,
        babyId: babyId,
        role: role,
        invitedAt: DateTime.now(),
      ),
    );
    _emitAll();
  }

  void updateMemberRole(String memberId, UserRole role) {
    final index = _members.indexWhere((m) => m.id == memberId);
    if (index != -1) _members[index] = _members[index].copyWith(role: role);
    _emitAll();
  }

  void updateMemberName(String memberId, String name) {
    final index = _members.indexWhere((m) => m.id == memberId);
    if (index != -1) _members[index] = _members[index].copyWith(name: name);
    _emitAll();
  }

  void removeMember(String memberId) {
    _members.removeWhere((m) => m.id == memberId);
    _emitAll();
  }

  void cancelInvitation(String invitationId) {
    _invitations.removeWhere((i) => i.id == invitationId);
    _emitAll();
  }

  void acceptInvitation(FamilyInvitation invitation, String uid, String name) {
    _members.add(
      FamilyMember(
        id: uid,
        name: name,
        email: invitation.email,
        role: UserRole.readOnly,
      ),
    );
    final index = _invitations.indexWhere((i) => i.id == invitation.id);
    if (index != -1) {
      _invitations[index] = FamilyInvitation(
        id: invitation.id,
        email: invitation.email,
        babyId: invitation.babyId,
        role: invitation.role,
        status: InvitationStatus.accepted,
        invitedAt: invitation.invitedAt,
      );
    }
    _emitAll();
  }

  void declineInvitation(String invitationId) {
    final index = _invitations.indexWhere((i) => i.id == invitationId);
    if (index != -1) {
      final inv = _invitations[index];
      _invitations[index] = FamilyInvitation(
        id: inv.id,
        email: inv.email,
        babyId: inv.babyId,
        role: inv.role,
        status: InvitationStatus.declined,
        invitedAt: inv.invitedAt,
      );
    }
    _emitAll();
  }

  // --- Foods ---
  List<Food> getAllFoods() => List.unmodifiable(_foods);

  Food? getFood(String id) => _foods.where((f) => f.id == id).firstOrNull;

  // --- Custom foods ---
  Stream<List<Food>> watchCustomFoods(String babyId) async* {
    yield List.unmodifiable(_customFoodsByBaby[babyId] ?? const []);
    yield* _customFoodsController.stream.map(
      (byBaby) => List.unmodifiable(byBaby[babyId] ?? const []),
    );
  }

  Food addCustomFood(String babyId, String name, FoodCategory category) {
    final food = Food(
      id: 'custom-food-${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      category: category,
    );
    _customFoodsByBaby.putIfAbsent(babyId, () => []).add(food);
    _customFoodsController.add(_customFoodsByBaby);
    return food;
  }

  // --- Meals ---
  Stream<List<Meal>> watchMeals(String babyId) async* {
    yield _meals.where((m) => m.babyId == babyId).toList();
    yield* _mealsController.stream.map(
      (meals) => meals.where((m) => m.babyId == babyId).toList(),
    );
  }

  String addMeal(Meal meal) {
    final id = meal.id.isNotEmpty
        ? meal.id
        : 'meal-${DateTime.now().microsecondsSinceEpoch}';
    _meals.add(
      Meal(
        id: id,
        babyId: meal.babyId,
        dateTime: meal.dateTime,
        foods: meal.foods,
        loggedByMemberId: meal.loggedByMemberId,
      ),
    );
    _emitAll();
    return id;
  }

  void updateMeal(Meal meal) {
    final index = _meals.indexWhere((m) => m.id == meal.id);
    if (index != -1) _meals[index] = meal;
    _emitAll();
  }

  void deleteMeal(String mealId) {
    _meals.removeWhere((m) => m.id == mealId);
    _emitAll();
  }

  // --- Notes ---
  Stream<List<FamilyNote>> watchNotes() async* {
    final sorted = [..._notes]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    yield List.unmodifiable(sorted);
    yield* _notesController.stream.map((notes) {
      final s = [...notes]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return s;
    });
  }

  void addNote(String text, String authorName) {
    _notes.add(
      FamilyNote(
        id: 'note-${_notes.length + 1}',
        text: text,
        authorName: authorName,
        updatedAt: DateTime.now(),
      ),
    );
    _emitAll();
  }

  void deleteNote(String noteId) {
    _notes.removeWhere((n) => n.id == noteId);
    _emitAll();
  }
}

class MockBabyRepository implements BabyRepository {
  final _store = MockDataStore.instance;

  @override
  Stream<List<BabyProfile>> watchBabies() => _store.watchBabies();

  @override
  Future<BabyProfile?> getBaby(String id) async => _store.getBaby(id);

  @override
  Future<String> addBaby(BabyProfile baby) async => _store.addBaby(baby);

  @override
  Future<void> updateBaby(BabyProfile baby) async => _store.updateBaby(baby);

  @override
  Future<void> deleteBaby(String babyId) async => _store.deleteBaby(babyId);
}

class MockMealRepository implements MealRepository {
  final _store = MockDataStore.instance;

  @override
  Stream<List<Meal>> watchMeals(String babyId) => _store.watchMeals(babyId);

  @override
  Future<String> addMeal(Meal meal) async => _store.addMeal(meal);

  @override
  Future<void> updateMeal(Meal meal) async => _store.updateMeal(meal);

  @override
  Future<void> deleteMeal(String babyId, String mealId) async =>
      _store.deleteMeal(mealId);
}

class MockFamilyRepository implements FamilyRepository {
  final _store = MockDataStore.instance;

  @override
  Stream<List<FamilyMember>> watchMembers(String babyId) =>
      _store.watchMembers();

  @override
  Stream<List<FamilyInvitation>> watchInvitations(String babyId) =>
      _store.watchInvitations();

  @override
  Future<void> invite(String babyId, String email, UserRole role) async =>
      _store.invite(babyId, email, role);

  @override
  Future<void> updateMemberRole(
    String babyId,
    String memberId,
    UserRole role,
  ) async => _store.updateMemberRole(memberId, role);

  @override
  Future<void> updateMemberName(
    String babyId,
    String memberId,
    String name,
  ) async => _store.updateMemberName(memberId, name);

  @override
  Future<void> removeMember(String babyId, String memberId) async =>
      _store.removeMember(memberId);

  @override
  Future<void> cancelInvitation(String babyId, String invitationId) async =>
      _store.cancelInvitation(invitationId);

  @override
  Future<List<FamilyMember>> getMembers(String babyId) async =>
      _store.watchMembers().first;

  @override
  Stream<List<FamilyInvitation>> watchMyPendingInvitations(String email) =>
      _store.watchInvitations().map(
        (invitations) => invitations
            .where(
              (i) => i.email == email && i.status == InvitationStatus.pending,
            )
            .toList(),
      );

  @override
  Future<void> acceptInvitation(
    FamilyInvitation invitation, {
    required String uid,
    required String name,
    required String email,
  }) async => _store.acceptInvitation(invitation, uid, name);

  @override
  Future<void> declineInvitation(FamilyInvitation invitation) async =>
      _store.declineInvitation(invitation.id);
}

class MockNoteRepository implements NoteRepository {
  final _store = MockDataStore.instance;

  @override
  Stream<List<FamilyNote>> watchNotes(String babyId) => _store.watchNotes();

  @override
  Future<void> addNote(String babyId, String text, String authorName) async =>
      _store.addNote(text, authorName);

  @override
  Future<void> clearNote(String babyId, String authorName) async =>
      _store.addNote('', authorName);

  @override
  Future<void> deleteNote(String babyId, String noteId) async =>
      _store.deleteNote(noteId);
}

class MockFoodRepository implements FoodRepository {
  final _store = MockDataStore.instance;

  @override
  Future<List<Food>> getAllFoods() async => _store.getAllFoods();

  @override
  Future<Food?> getFood(String id) async => _store.getFood(id);

  @override
  Stream<List<Food>> watchCustomFoods(String babyId) =>
      _store.watchCustomFoods(babyId);

  @override
  Future<Food> addCustomFood(
    String babyId,
    String name,
    FoodCategory category,
  ) async => _store.addCustomFood(babyId, name, category);
}
