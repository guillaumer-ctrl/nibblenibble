import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/family_invitation.dart';
import '../../models/family_member.dart';
import '../../models/user_role.dart';
import '../repositories/family_repository.dart';
import 'firestore_instance.dart';

UserRole _roleFromString(String value) =>
    value == 'admin' ? UserRole.admin : UserRole.readOnly;

String _roleToString(UserRole role) =>
    role == UserRole.admin ? 'admin' : 'readOnly';

FamilyMember _memberFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
  final data = doc.data()!;
  return FamilyMember(
    id: doc.id,
    name: data['name'] as String? ?? '',
    email: data['email'] as String? ?? '',
    role: _roleFromString(data['role'] as String? ?? 'readOnly'),
  );
}

FamilyInvitation _invitationFromDoc(
  DocumentSnapshot<Map<String, dynamic>> doc,
  String babyId,
) {
  final data = doc.data()!;
  return FamilyInvitation(
    id: doc.id,
    email: data['email'] as String,
    babyId: babyId,
    role: _roleFromString(data['role'] as String? ?? 'readOnly'),
    status: InvitationStatus.values.firstWhere(
      (s) => s.name == (data['status'] as String? ?? 'pending'),
      orElse: () => InvitationStatus.pending,
    ),
    invitedAt: (data['invitedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
  );
}

class FirestoreFamilyRepository implements FamilyRepository {
  FirestoreFamilyRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? appFirestore;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _membersOf(String babyId) =>
      _db.collection('babies').doc(babyId).collection('members');

  CollectionReference<Map<String, dynamic>> _invitationsOf(String babyId) =>
      _db.collection('babies').doc(babyId).collection('invitations');

  @override
  Stream<List<FamilyMember>> watchMembers(String babyId) => _membersOf(
    babyId,
  ).snapshots().map((snap) => snap.docs.map(_memberFromDoc).toList());

  @override
  Future<List<FamilyMember>> getMembers(String babyId) async {
    final snap = await _membersOf(babyId).get();
    return snap.docs.map(_memberFromDoc).toList();
  }

  @override
  Stream<List<FamilyInvitation>> watchInvitations(String babyId) =>
      _invitationsOf(babyId).where('status', isEqualTo: 'pending').snapshots().map(
        (snap) =>
            snap.docs.map((d) => _invitationFromDoc(d, babyId)).toList(),
      );

  @override
  Future<void> invite(String babyId, String email, UserRole role) async {
    // Lowercase, always: Firebase Auth normalizes request.auth.token.email
    // to lowercase, and the member-doc-acceptance rule does an exact
    // exists()/get() on invitations/{that email}. Any case mismatch here
    // (e.g. an admin typing "Jean@..." for a token that's "jean@...") would
    // make that lookup silently miss and deny the invited user's own join.
    final normalizedEmail = email.trim().toLowerCase();

    // Deterministic doc id (the email itself), not .add(): the invited
    // user's own member-doc-creation rule needs to `get()` this exact
    // invitation by an exact path to verify it — Firestore rules can't
    // check "does some doc matching a query exist". Re-inviting the same
    // email just refreshes the same pending invitation (including its role,
    // if re-sent with a different one before being accepted).
    await _invitationsOf(babyId).doc(normalizedEmail).set({
      'email': normalizedEmail,
      'role': _roleToString(role),
      'status': 'pending',
      'invitedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> updateMemberRole(
    String babyId,
    String memberId,
    UserRole role,
  ) async {
    await _membersOf(babyId).doc(memberId).update({
      'role': _roleToString(role),
    });
  }

  @override
  Future<void> updateMemberName(
    String babyId,
    String memberId,
    String name,
  ) async {
    await _membersOf(babyId).doc(memberId).update({'name': name});
  }

  @override
  Future<void> cancelInvitation(String babyId, String invitationId) async {
    await _invitationsOf(babyId).doc(invitationId).delete();
  }

  @override
  Future<void> removeMember(String babyId, String memberId) async {
    await _membersOf(babyId).doc(memberId).delete();
  }

  @override
  Stream<List<FamilyInvitation>> watchMyPendingInvitations(String email) {
    if (email.isEmpty) return Stream.value(const []);
    return _db
        .collectionGroup('invitations')
        .where('email', isEqualTo: email)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) {
            final babyId = d.reference.parent.parent!.id;
            return _invitationFromDoc(d, babyId);
          }).toList(),
        )
        // The signed-in account can be deleted server-side (another device,
        // or manual cleanup during testing) while this stream is still
        // live; refreshing the ID token for the next query then throws
        // (firebase_auth/unknown) instead of just closing the stream.
        // Treat that like "no invitations" rather than let an auth error
        // escape as an unhandled, fatal stream error (Crashlytics).
        .transform(
          StreamTransformer.fromHandlers(
            handleError: (Object error, StackTrace stack, sink) {
              if (error is FirebaseException) {
                sink.add(const []);
              } else {
                sink.addError(error, stack);
              }
            },
          ),
        );
  }

  @override
  Future<void> acceptInvitation(
    FamilyInvitation invitation, {
    required String uid,
    required String name,
    required String email,
  }) async {
    final babyRef = _db.collection('babies').doc(invitation.babyId);
    // Batched (atomic): three writes that must land together or not at all
    // — a dropped connection between them used to be able to leave a member
    // created but the invitation still "pending" forever. Safe to batch
    // here (unlike addBaby's baby-doc + member-doc pair): every rule these
    // three writes are checked against only reads *this* invitation doc or
    // the acting user's own auth/uid, never another doc from this same
    // batch, so pre-batch-state rule evaluation can't misfire.
    final batch = _db.batch();
    batch.set(babyRef.collection('members').doc(uid), {
      'uid': uid,
      'name': name,
      'email': email,
      'role': _roleToString(invitation.role),
      'joinedAt': FieldValue.serverTimestamp(),
    });
    batch.update(babyRef.collection('invitations').doc(invitation.id), {
      'status': 'accepted',
    });
    batch.set(_db.collection('users').doc(uid), {
      'babyIds': FieldValue.arrayUnion([invitation.babyId]),
    }, SetOptions(merge: true));
    await batch.commit();
  }

  @override
  Future<void> declineInvitation(FamilyInvitation invitation) async {
    await _db
        .collection('babies')
        .doc(invitation.babyId)
        .collection('invitations')
        .doc(invitation.id)
        .update({'status': 'declined'});
  }
}
