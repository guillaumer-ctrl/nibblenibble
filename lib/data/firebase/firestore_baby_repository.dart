import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/baby_profile.dart';
import '../repositories/baby_repository.dart';
import 'firestore_instance.dart';

BabyGender _genderFromString(String? value) => BabyGender.values.firstWhere(
  (g) => g.name == value,
  orElse: () => BabyGender.nonPrecise,
);

BabyProfile _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
  final data = doc.data()!;
  return BabyProfile(
    id: doc.id,
    name: data['name'] as String,
    birthDate: (data['birthDate'] as Timestamp).toDate(),
    diversificationStartDate:
        (data['diversificationStartDate'] as Timestamp?)?.toDate(),
    gender: _genderFromString(data['gender'] as String?),
  );
}

class FirestoreBabyRepository implements BabyRepository {
  FirestoreBabyRepository({
    required String currentUserId,
    required String currentUserName,
    String? currentUserEmail,
    FirebaseFirestore? firestore,
  }) : _uid = currentUserId,
       _userName = currentUserName,
       _userEmail = currentUserEmail,
       _db = firestore ?? appFirestore;

  final String _uid;
  final String _userName;
  final String? _userEmail;
  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      _db.collection('users').doc(_uid);

  CollectionReference<Map<String, dynamic>> get _babies =>
      _db.collection('babies');

  @override
  Stream<List<BabyProfile>> watchBabies() {
    return _userDoc.snapshots().asyncExpand((userSnap) {
      final babyIds = List<String>.from(
        (userSnap.data()?['babyIds'] as List?) ?? const [],
      );
      if (babyIds.isEmpty) return Stream.value(<BabyProfile>[]);
      // Firestore's whereIn caps at 30 values; fine for a family app.
      return _babies
          .where(FieldPath.documentId, whereIn: babyIds)
          .snapshots()
          .map((snap) => snap.docs.map(_fromDoc).toList());
    });
  }

  @override
  Future<BabyProfile?> getBaby(String id) async {
    final doc = await _babies.doc(id).get();
    return doc.exists ? _fromDoc(doc) : null;
  }

  /// Creates a baby profile, then makes the current user its first admin.
  /// These are two *sequential* writes, not one batch: the member doc's
  /// create rule does `get(babies/{babyId}).data.createdBy` to verify the
  /// bootstrap, and within a single atomic batch that get() sees the
  /// pre-batch state — the baby doc doesn't exist yet from the rule
  /// engine's point of view, so the write is denied. Awaiting the baby
  /// doc's write first means it's genuinely committed before the member
  /// doc's rule evaluates.
  @override
  Future<String> addBaby(BabyProfile baby) async {
    final babyRef = _babies.doc();

    await babyRef.set({
      'name': baby.name,
      'birthDate': Timestamp.fromDate(baby.birthDate),
      'diversificationStartDate': baby.diversificationStartDate == null
          ? null
          : Timestamp.fromDate(baby.diversificationStartDate!),
      'gender': baby.gender.name,
      'createdBy': _uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await babyRef.collection('members').doc(_uid).set({
      'uid': _uid,
      'name': _userName,
      'email': _userEmail,
      'role': 'admin',
      'joinedAt': FieldValue.serverTimestamp(),
    });

    await _userDoc.set({
      'babyIds': FieldValue.arrayUnion([babyRef.id]),
    }, SetOptions(merge: true));

    return babyRef.id;
  }

  @override
  Future<void> updateBaby(BabyProfile baby) async {
    await _babies.doc(baby.id).update({
      'name': baby.name,
      'birthDate': Timestamp.fromDate(baby.birthDate),
      'diversificationStartDate': baby.diversificationStartDate == null
          ? null
          : Timestamp.fromDate(baby.diversificationStartDate!),
      'gender': baby.gender.name,
    });
  }

  /// Best-effort cascade: Firestore never deletes subcollections on its
  /// own. Meals, members, invitations and custom foods are cleaned up (the
  /// rules permit an admin to delete all four); notes are left as harmless
  /// orphans — no rule permits deleting a note, deliberately: it's an
  /// append-only history by design, not an oversight.
  ///
  /// Only the *current* user's own `/users/{uid}` doc is updated here — the
  /// write rule on that collection is `request.auth.uid == uid`, so an
  /// admin can't touch another member's doc (and there's no Cloud Function
  /// to do it server-side on the Spark plan). A batch is atomic: trying to
  /// write every member's doc would make the whole deletion fail the moment
  /// there's more than one member. Other members keep a dangling babyId in
  /// their array; harmless, since `watchBabies()`'s `whereIn` query just
  /// silently drops ids that no longer resolve to a baby doc.
  @override
  Future<void> deleteBaby(String babyId) async {
    final babyRef = _babies.doc(babyId);
    final membersSnap = await babyRef.collection('members').get();
    final mealsSnap = await babyRef.collection('meals').get();
    final invitationsSnap = await babyRef.collection('invitations').get();
    final customFoodsSnap = await babyRef.collection('customFoods').get();

    final batch = _db.batch();
    for (final doc in mealsSnap.docs) {
      batch.delete(doc.reference);
    }
    for (final doc in membersSnap.docs) {
      batch.delete(doc.reference);
    }
    for (final doc in invitationsSnap.docs) {
      batch.delete(doc.reference);
    }
    for (final doc in customFoodsSnap.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(babyRef);
    batch.set(_userDoc, {
      'babyIds': FieldValue.arrayRemove([babyId]),
    }, SetOptions(merge: true));
    await batch.commit();
  }
}
