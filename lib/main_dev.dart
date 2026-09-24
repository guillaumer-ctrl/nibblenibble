// Dev-only entrypoint: runs the app against the in-memory mock data instead
// of Firebase, so the UI can be previewed in a browser without a device or
// a registered Firebase web app. Never used for the real app (see main.dart).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'data/mock/mock_data_source.dart';
import 'data/repositories/auth_repository.dart';
import 'providers/app_providers.dart';
import 'providers/auth_providers.dart';

class _DevAuthRepository implements AuthRepository {
  static const _user = AppUser(uid: 'dev-uid', displayName: 'Camille');

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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR');
  await initializeDateFormatting('en_US');
  runApp(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(_DevAuthRepository()),
        babyRepositoryProvider.overrideWithValue(MockBabyRepository()),
        mealRepositoryProvider.overrideWithValue(MockMealRepository()),
        familyRepositoryProvider.overrideWithValue(MockFamilyRepository()),
        foodRepositoryProvider.overrideWithValue(MockFoodRepository()),
        noteRepositoryProvider.overrideWithValue(MockNoteRepository()),
      ],
      child: const NibbleNibbleApp(),
    ),
  );
}
