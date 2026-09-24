import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// The app's Firestore database. "nibblenibble" is the Firebase *project*
/// id, not a separate named database — the project only has the
/// "(default)" database, so this is equivalent to `FirebaseFirestore.instance`.
/// Kept as one explicit instance (rather than the bare singleton) so every
/// repository/provider goes through a single, obvious place if that ever
/// changes.
final appFirestore = FirebaseFirestore.instanceFor(
  app: Firebase.app(),
  databaseId: '(default)',
);
