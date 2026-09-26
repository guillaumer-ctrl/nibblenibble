import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:nibblenibble/app.dart';
import 'package:nibblenibble/data/mock/mock_data_source.dart';
import 'package:nibblenibble/data/repositories/auth_repository.dart';
import 'package:nibblenibble/providers/app_providers.dart';
import 'package:nibblenibble/providers/auth_providers.dart';
import 'package:nibblenibble/providers/locale_provider.dart';

/// Signed in as `member-camille`, the admin seeded in [MockDataStore] — so
/// `isCurrentUserAdminProvider` resolves true and the "+" add-meal tab is
/// available, same as it would be for the real admin using the app.
class _FakeAdminAuthRepository implements AuthRepository {
  static const _user = AppUser(uid: 'member-camille', displayName: 'Camille');

  @override
  AppUser? get currentUser => _user;

  @override
  Stream<AppUser?> authStateChanges() => Stream.value(_user);

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async => _user;

  @override
  Future<({AppUser user, bool isNewUser})> signInWithGoogle() async =>
      (user: _user, isNewUser: false);

  @override
  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async => _user;

  @override
  Future<void> updateDisplayName(String displayName) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<void> deleteAccount() async {}
}

void main() {
  testWidgets(
    'Golden path: open the app, add a meal with a food, and see it saved',
    (WidgetTester tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(_FakeAdminAuthRepository()),
            // Real repositories talk to Firestore, unavailable in widget tests.
            babyRepositoryProvider.overrideWithValue(MockBabyRepository()),
            mealRepositoryProvider.overrideWithValue(MockMealRepository()),
            familyRepositoryProvider.overrideWithValue(MockFamilyRepository()),
            foodRepositoryProvider.overrideWithValue(MockFoodRepository()),
            noteRepositoryProvider.overrideWithValue(MockNoteRepository()),
            localeProvider.overrideWith((ref) => const Locale('en', 'US')),
          ],
          child: const NibbleNibbleApp(),
        ),
      );
      // Lets authStateProvider's stream settle before anything reads
      // currentUserProvider — same pattern as widget_test.dart.
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      final mealsBefore = await MockDataStore.instance.watchMeals('baby-lea').first;

      // Open the add-meal form from the bottom nav's "+" tab (only shown to
      // admins, which member-camille is).
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      expect(find.text("Choose the meal's date & time first."), findsOneWidget);

      // Pick a date, then a time — both pickers default to "now", so simply
      // confirming each is enough to move the flow forward.
      await tester.tap(find.text('Choose the date & time'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // The food list is now visible — select an existing food (English name,
      // since the test app's locale is overridden to English above).
      expect(find.text('Carrot'), findsOneWidget);
      await tester.tap(find.text('Carrot'));
      await tester.pumpAndSettle();

      // Save and confirm the meal was actually persisted.
      await tester.tap(find.text('Save (1)'));
      await tester.pumpAndSettle();

      expect(find.text('Meal added.'), findsOneWidget);
      final mealsAfter = await MockDataStore.instance.watchMeals('baby-lea').first;
      expect(mealsAfter.length, mealsBefore.length + 1);
      final added = mealsAfter.firstWhere(
        (m) => !mealsBefore.any((existing) => existing.id == m.id),
      );
      expect(added.foods.single.foodId, 'food-carotte');

      // Let the success snackbar's own auto-dismiss timer (AppSnackBar._insert)
      // fire before the test ends — otherwise the binding fails the test for
      // a timer still pending after the widget tree is torn down.
      await tester.pump(const Duration(seconds: 4));
    },
  );
}
