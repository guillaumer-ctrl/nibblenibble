/// Minimal shape we need from a signed-in user, independent of Firebase types
/// so screens/providers never import firebase_auth directly.
class AppUser {
  const AppUser({required this.uid, this.email, this.displayName});

  final String uid;
  final String? email;
  final String? displayName;
}

abstract class AuthRepository {
  Stream<AppUser?> authStateChanges();

  AppUser? get currentUser;

  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  });

  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  });

  /// `isNewUser` tells the caller whether this Google identity just created
  /// its first-ever nibblenibble account or signed into an existing one —
  /// needed so sign-up (unlike sign-in) can skip onboarding for a returning
  /// user instead of always pushing "create a baby profile" on top of an
  /// account that may already have one.
  Future<({AppUser user, bool isNewUser})> signInWithGoogle();

  Future<void> updateDisplayName(String displayName);

  Future<void> signOut();

  /// Deletes the Firebase Auth account itself. Call after cleaning up the
  /// user's own Firestore data (member docs, /users/{uid}) — once this
  /// succeeds, request.auth is gone and further writes as this user would
  /// be rejected anyway.
  Future<void> deleteAccount();
}

/// Thrown for any auth failure. Carries a stable code (Firebase's own error
/// code, or one of this app's synthetic ones for non-Firebase failures like
/// a cancelled Google sign-in) rather than a pre-translated message — the UI
/// layer maps it to displayable text via AppStrings.authErrorMessage, since
/// this repository has no BuildContext/locale to translate with itself.
class AuthException implements Exception {
  const AuthException(this.code);
  final String code;

  @override
  String toString() => code;
}
