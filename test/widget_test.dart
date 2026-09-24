import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:nibblenibble/app.dart';
import 'package:nibblenibble/data/mock/mock_data_source.dart';
import 'package:nibblenibble/data/repositories/auth_repository.dart';
import 'package:nibblenibble/providers/app_providers.dart';
import 'package:nibblenibble/providers/auth_providers.dart';

/// A signed-in stand-in so widget tests don't need a real Firebase project.
class FakeSignedInAuthRepository implements AuthRepository {
  static const _user = AppUser(uid: 'test-uid', displayName: 'Camille');

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
  testWidgets('Home screen shows a greeting and the wordmark', (
    WidgetTester tester,
  ) async {
    GoogleFonts.config.allowRuntimeFetching = false;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeSignedInAuthRepository(),
          ),
          // Real repositories talk to Firestore, unavailable in widget tests.
          babyRepositoryProvider.overrideWithValue(MockBabyRepository()),
          mealRepositoryProvider.overrideWithValue(MockMealRepository()),
          familyRepositoryProvider.overrideWithValue(MockFamilyRepository()),
          foodRepositoryProvider.overrideWithValue(MockFoodRepository()),
          noteRepositoryProvider.overrideWithValue(MockNoteRepository()),
        ],
        child: const NibbleNibbleApp(),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.textContaining('Bonjour'), findsOneWidget);
    // The mock data seeds recent meals, so the home "Ajouter un repas"
    // button is correctly hidden (it only shows when the list is empty) —
    // "Prochains repas" is the stable marker that the meals list rendered.
    expect(find.text('Prochains repas'), findsOneWidget);
  });
}
