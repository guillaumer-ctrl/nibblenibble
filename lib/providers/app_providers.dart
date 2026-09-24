import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../data/firebase/firestore_baby_repository.dart';
import '../data/firebase/firestore_family_repository.dart';
import '../data/firebase/firestore_food_repository.dart';
import '../data/firebase/firestore_instance.dart';
import '../data/firebase/firestore_meal_repository.dart';
import '../data/firebase/firestore_note_repository.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/baby_repository.dart';
import '../data/repositories/family_repository.dart';
import '../data/repositories/food_repository.dart';
import '../data/repositories/meal_repository.dart';
import '../data/repositories/note_repository.dart';
import '../models/baby_profile.dart';
import '../models/family_invitation.dart';
import '../models/family_member.dart';
import '../models/family_note.dart';
import '../models/food.dart';
import '../models/meal.dart';
import '../models/reaction.dart';
import '../models/user_role.dart';
import 'auth_providers.dart';

/// Only ever watched from inside the authenticated part of the app (see
/// _AuthGate in app.dart), where authStateProvider is guaranteed non-null.
AppUser? _lastKnownUser;

final currentUserProvider = Provider<AppUser>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user != null) {
    _lastKnownUser = user;
    return user;
  }
  // Signing out flips authStateProvider to null a frame or two before every
  // other provider that was still (transiently) watching this one — from
  // the about-to-be-torn-down RootShell subtree — gets disposed. Falling
  // back to the last signed-in user for that one frame turns a harmless
  // teardown race into a no-op instead of a crash; nothing reads this once
  // AuthGate finishes swapping to WelcomeScreen.
  final cached = _lastKnownUser;
  if (cached != null) return cached;
  throw StateError('currentUserProvider read before authentication');
});

final babyRepositoryProvider = Provider<BabyRepository>((ref) {
  final user = ref.watch(currentUserProvider);
  // myDisplayNameProvider (Firestore) first, not Firebase Auth's own
  // displayName — see that provider's doc comment. Without this, creating a
  // baby always stamped the founding admin's own member doc with whatever
  // Firebase Auth's displayName happened to be (the Google account's name,
  // for a Google sign-in) regardless of the pseudo already set in Compte.
  final customName = ref.watch(myDisplayNameProvider).value;
  return FirestoreBabyRepository(
    currentUserId: user.uid,
    currentUserName: customName ?? user.displayName ?? user.email ?? 'Moi',
    currentUserEmail: user.email,
  );
});
final mealRepositoryProvider = Provider<MealRepository>(
  (ref) => FirestoreMealRepository(),
);
final familyRepositoryProvider = Provider<FamilyRepository>(
  (ref) => FirestoreFamilyRepository(),
);
final foodRepositoryProvider = Provider<FoodRepository>(
  (ref) => FirestoreFoodRepository(),
);
final noteRepositoryProvider = Provider<NoteRepository>(
  (ref) => FirestoreNoteRepository(),
);

final foodsProvider = FutureProvider<List<Food>>(
  (ref) => ref.watch(foodRepositoryProvider).getAllFoods(),
);

/// Foods the currently selected baby's family added themselves, on top of
/// the shared database — see FoodRepository's doc comment.
final customFoodsProvider = StreamProvider<List<Food>>((ref) {
  final baby = ref.watch(selectedBabyProvider);
  if (baby == null) return Stream.value(const []);
  return ref.watch(foodRepositoryProvider).watchCustomFoods(baby.id);
});

/// Every food usable for the currently selected baby: the shared database
/// plus whatever this family added themselves.
final allFoodsProvider = Provider<List<Food>>((ref) {
  final shared = ref.watch(foodsProvider).value ?? const [];
  final custom = ref.watch(customFoodsProvider).value ?? const [];
  return [...shared, ...custom];
});

/// Convenience lookup so meal cards can show food names instead of raw ids.
final foodsByIdProvider = Provider<Map<String, Food>>((ref) {
  return {for (final f in ref.watch(allFoodsProvider)) f.id: f};
});

final babiesProvider = StreamProvider<List<BabyProfile>>(
  (ref) => ref.watch(babyRepositoryProvider).watchBabies(),
);

/// The baby currently selected via the profile switcher in the topbar.
final selectedBabyIdProvider = StateProvider<String?>((ref) => null);

final selectedBabyProvider = Provider<BabyProfile?>((ref) {
  final babies = ref.watch(babiesProvider).value ?? [];
  final selectedId = ref.watch(selectedBabyIdProvider);
  if (babies.isEmpty) return null;
  // No explicit selection yet (very first launch) — default to the first
  // baby. Once a specific id *has* been selected (e.g. right after
  // creating a new baby), falling back to babies.first when that id isn't
  // in the list yet used to silently show a *different* baby's data —
  // babiesProvider's stream can lag a moment behind its own just-committed
  // write (see AddBabyScreen._submit), so the freshly created baby's id
  // briefly doesn't match anything here. Returning null instead lets
  // screens fall back to their existing loading state until the stream
  // catches up and this recomputes to the right baby.
  if (selectedId == null) return babies.first;
  return babies.where((b) => b.id == selectedId).firstOrNull;
});

final mealsForSelectedBabyProvider = StreamProvider<List<Meal>>((ref) {
  final baby = ref.watch(selectedBabyProvider);
  // Stream.value([]), not Stream.empty(): an empty stream never emits, which
  // would leave a StreamProvider stuck in AsyncLoading forever.
  if (baby == null) return Stream.value(const []);
  return ref.watch(mealRepositoryProvider).watchMeals(baby.id);
});

/// A food only ever has *one* current reaction from the baby, even though
/// it's stored per meal-food-entry — this is "the" reaction for a food:
/// whichever one was recorded most recently. `watchMeals` already orders by
/// dateTime descending, so the first non-null reaction found per food as we
/// walk the list is the latest one.
final foodReactionsProvider = Provider<Map<String, Reaction>>((ref) {
  final meals = ref.watch(mealsForSelectedBabyProvider).value ?? const [];
  final result = <String, Reaction>{};
  for (final meal in meals) {
    for (final entry in meal.foods) {
      if (entry.reaction != null) {
        result.putIfAbsent(entry.foodId, () => entry.reaction!);
      }
    }
  }
  return result;
});

/// How many past meals have included each food, ever — shown in the meal
/// form so a parent can see at a glance whether/how often a food has
/// already been served, regardless of what reaction (if any) it got.
final foodUsageCountsProvider = Provider<Map<String, int>>((ref) {
  final meals = ref.watch(mealsForSelectedBabyProvider).value ?? const [];
  final result = <String, int>{};
  for (final meal in meals) {
    if (!meal.isPast) continue;
    for (final entry in meal.foods) {
      result.update(entry.foodId, (n) => n + 1, ifAbsent: () => 1);
    }
  }
  return result;
});

final familyMembersProvider = StreamProvider<List<FamilyMember>>((ref) {
  final baby = ref.watch(selectedBabyProvider);
  if (baby == null) return Stream.value(const []);
  return ref.watch(familyRepositoryProvider).watchMembers(baby.id);
});

/// Convenience lookup so meal cards can show who logged a meal by name
/// instead of a raw member id.
final familyMembersByIdProvider = Provider<Map<String, FamilyMember>>((ref) {
  final members = ref.watch(familyMembersProvider).value ?? const [];
  return {for (final m in members) m.id: m};
});

final familyInvitationsProvider = StreamProvider<List<FamilyInvitation>>((
  ref,
) {
  final baby = ref.watch(selectedBabyProvider);
  if (baby == null) return Stream.value(const []);
  return ref.watch(familyRepositoryProvider).watchInvitations(baby.id);
});

final familyNotesProvider = StreamProvider<List<FamilyNote>>((ref) {
  final baby = ref.watch(selectedBabyProvider);
  if (baby == null) return Stream.value(const []);
  return ref.watch(noteRepositoryProvider).watchNotes(baby.id);
});

final currentNoteProvider = Provider<FamilyNote?>(
  (ref) => ref.watch(familyNotesProvider).value?.firstOrNull,
);

/// Invitations addressed to the signed-in user's email, across every baby
/// — this is how a newly invited account discovers what it was invited to
/// (there's no other UI path that would surface it otherwise).
final myPendingInvitationsProvider = StreamProvider<List<FamilyInvitation>>((
  ref,
) {
  final email = ref.watch(currentUserProvider).email;
  if (email == null || email.isEmpty) return Stream.value(const []);
  return ref.watch(familyRepositoryProvider).watchMyPendingInvitations(email);
});

final currentMemberIdProvider = Provider<String>(
  (ref) => ref.watch(currentUserProvider).uid,
);

/// The name the user chose in Compte, stored in Firestore rather than
/// relying on Firebase Auth's own `displayName` — Google Sign-In re-syncs
/// that field from the Google account's profile name on every sign-in
/// (not just the first), silently overwriting any custom name set via
/// `updateDisplayName`. Firestore is the one place this app fully owns.
/// Null (not empty string) when nothing custom has been saved yet, so call
/// sites can fall back to Firebase's displayName/email themselves.
final myDisplayNameProvider = StreamProvider<String?>((ref) {
  final uid = ref.watch(currentUserProvider).uid;
  return appFirestore.collection('users').doc(uid).snapshots().map((doc) {
    final name = doc.data()?['displayName'] as String?;
    return (name == null || name.isEmpty) ? null : name;
  });
});

/// Whether the signed-in user is admin on the currently selected baby —
/// gates meal editing/deletion and family management in the UI (the real
/// enforcement lives in firestore.rules; this only drives what's shown).
final isCurrentUserAdminProvider = Provider<bool>((ref) {
  final members = ref.watch(familyMembersProvider).value ?? const [];
  final uid = ref.watch(currentMemberIdProvider);
  final me = members.where((m) => m.id == uid).firstOrNull;
  return me?.role == UserRole.admin;
});
