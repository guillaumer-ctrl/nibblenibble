import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nibblenibble/data/firebase/firestore_baby_repository.dart';
import 'package:nibblenibble/models/baby_profile.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FirestoreBabyRepository repo;
  const uid = 'user-1';

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repo = FirestoreBabyRepository(
      currentUserId: uid,
      currentUserName: 'Camille',
      currentUserEmail: 'camille@example.com',
      firestore: firestore,
    );
  });

  test('addBaby creates the baby doc, the founding admin member doc, and links the user', () async {
    await repo.addBaby(
      BabyProfile(id: '', name: 'Léo', birthDate: DateTime(2025, 6, 1)),
    );

    final babies = await firestore.collection('babies').get();
    expect(babies.docs, hasLength(1));
    final babyId = babies.docs.single.id;
    expect(babies.docs.single.data()['name'], 'Léo');
    expect(babies.docs.single.data()['createdBy'], uid);

    final memberDoc = await firestore
        .collection('babies')
        .doc(babyId)
        .collection('members')
        .doc(uid)
        .get();
    expect(memberDoc.data()?['role'], 'admin');
    expect(memberDoc.data()?['name'], 'Camille');

    final userDoc = await firestore.collection('users').doc(uid).get();
    expect(userDoc.data()?['babyIds'], contains(babyId));
  });

  test('deleteBaby cascades meals, members, invitations and custom foods, but leaves notes', () async {
    await repo.addBaby(
      BabyProfile(id: '', name: 'Léo', birthDate: DateTime(2025, 6, 1)),
    );
    final babyId = (await firestore.collection('babies').get()).docs.single.id;
    final babyRef = firestore.collection('babies').doc(babyId);

    await babyRef.collection('meals').add({'dateTime': DateTime.now()});
    await babyRef.collection('invitations').doc('a@b.com').set({
      'email': 'a@b.com',
    });
    await babyRef.collection('customFoods').add({'name': 'Riz', 'category': 'feculents'});
    await babyRef.collection('notes').add({'text': 'Note à garder'});

    await repo.deleteBaby(babyId);

    expect((await babyRef.get()).exists, isFalse);
    expect((await babyRef.collection('meals').get()).docs, isEmpty);
    expect((await babyRef.collection('members').get()).docs, isEmpty);
    expect((await babyRef.collection('invitations').get()).docs, isEmpty);
    expect((await babyRef.collection('customFoods').get()).docs, isEmpty);
    // Notes are append-only history — deliberately never deleted.
    expect((await babyRef.collection('notes').get()).docs, hasLength(1));

    final userDoc = await firestore.collection('users').doc(uid).get();
    expect(userDoc.data()?['babyIds'], isNot(contains(babyId)));
  });
}
