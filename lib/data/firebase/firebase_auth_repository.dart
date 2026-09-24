import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';

import '../repositories/auth_repository.dart';
import 'firestore_instance.dart';

/// The "Web client ID" (OAuth client, type 3) from google-services.json —
/// required on Android so GoogleSignIn can request an ID token Firebase
/// will accept. Safe to keep in source: it identifies the app, it's not a
/// secret (there's no client secret involved in this flow).
const _googleServerClientId =
    '1045105533398-ni8asoa62kr6cm58nioa75v69bb8us86.apps.googleusercontent.com';

AppUser _toAppUser(fb.User user) => AppUser(
  uid: user.uid,
  email: user.email,
  displayName: user.displayName,
);

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({fb.FirebaseAuth? firebaseAuth})
    : _auth = firebaseAuth ?? fb.FirebaseAuth.instance;

  final fb.FirebaseAuth _auth;
  bool _googleSignInInitialized = false;
  String? _lastNetworkResetUid;

  @override
  // userChanges(), not authStateChanges(): also emits after profile edits
  // (e.g. updateDisplayName), not just sign-in/out, so the UI reflects a
  // changed name without needing a manual refresh.
  Stream<AppUser?> authStateChanges() async* {
    try {
      await for (final u in _auth.userChanges()) {
        if (u != null && _lastNetworkResetUid != u.uid) {
          _lastNetworkResetUid = u.uid;
          // Workaround for a known Firestore Android SDK bug: a Listen
          // stream opened before this sign-in (or before the fresh token
          // propagated) never picks up the new credential on its own and
          // keeps failing with PERMISSION_DENIED forever, even though a
          // plain get() with the same token succeeds right away —
          // https://github.com/firebase/firebase-android-sdk/issues/5101.
          // Toggling the network off/on forces every active/retrying
          // listener to tear down and reopen, reattaching the now-valid
          // token.
          try {
            await appFirestore.disableNetwork();
            await appFirestore.enableNetwork();
          } catch (_) {}
        } else if (u == null) {
          _lastNetworkResetUid = null;
        }
        yield u == null ? null : _toAppUser(u);
      }
    } on fb.FirebaseAuthException catch (e) {
      // Right after this account deletes itself, Firebase's own automatic
      // token-refresh check on the now-gone account can error instead of
      // just emitting null — signed out either way, so treat it as that
      // rather than letting a real exception reach the UI.
      if (e.code == 'user-not-found') {
        _lastNetworkResetUid = null;
        yield null;
      } else {
        rethrow;
      }
    }
  }

  @override
  AppUser? get currentUser {
    final user = _auth.currentUser;
    return user == null ? null : _toAppUser(user);
  }

  @override
  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user?.updateDisplayName(displayName);
      await credential.user?.reload();
      return _toAppUser(_auth.currentUser!);
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(e.code);
    }
  }

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _toAppUser(credential.user!);
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(e.code);
    }
  }

  @override
  Future<({AppUser user, bool isNewUser})> signInWithGoogle() async {
    try {
      if (!_googleSignInInitialized) {
        await GoogleSignIn.instance.initialize(
          serverClientId: _googleServerClientId,
        );
        _googleSignInInitialized = true;
      }
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const AuthException('google-sign-in-unavailable');
      }
      final credential = fb.GoogleAuthProvider.credential(idToken: idToken);
      final userCredential = await _auth.signInWithCredential(credential);
      return (
        user: _toAppUser(userCredential.user!),
        isNewUser: userCredential.additionalUserInfo?.isNewUser ?? false,
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthException('google-sign-in-cancelled');
      }
      throw const AuthException('google-sign-in-failed');
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(e.code);
    }
  }

  @override
  Future<void> updateDisplayName(String displayName) async {
    await _auth.currentUser?.updateDisplayName(displayName);
    await _auth.currentUser?.reload();
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    if (_googleSignInInitialized) {
      await GoogleSignIn.instance.signOut();
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(e.code);
    }
  }
}
