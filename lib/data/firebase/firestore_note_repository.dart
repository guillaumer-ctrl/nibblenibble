import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/family_note.dart';
import '../repositories/note_repository.dart';
import 'firestore_instance.dart';

class FirestoreNoteRepository implements NoteRepository {
  FirestoreNoteRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? appFirestore;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _notesOf(String babyId) =>
      _db.collection('babies').doc(babyId).collection('notes');

  @override
  Stream<List<FamilyNote>> watchNotes(String babyId) => _notesOf(babyId)
      .orderBy('updatedAt', descending: true)
      .snapshots()
      .map(
        (snap) => snap.docs.map((d) {
          final data = d.data();
          return FamilyNote(
            id: d.id,
            text: data['text'] as String,
            authorName: data['authorName'] as String? ?? '',
            updatedAt:
                (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          );
        }).toList(),
      );

  @override
  Future<void> addNote(String babyId, String text, String authorName) async {
    await _notesOf(babyId).add({
      'text': text,
      'authorName': authorName,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> clearNote(String babyId, String authorName) =>
      addNote(babyId, '', authorName);

  @override
  Future<void> deleteNote(String babyId, String noteId) =>
      _notesOf(babyId).doc(noteId).delete();
}
