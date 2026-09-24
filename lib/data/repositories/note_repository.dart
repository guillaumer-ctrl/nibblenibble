import '../../models/family_note.dart';

abstract class NoteRepository {
  /// Newest first — the first item is the current note shown on the home
  /// screen, the rest is history.
  Stream<List<FamilyNote>> watchNotes(String babyId);

  Future<void> addNote(String babyId, String text, String authorName);

  /// Clears the current note text (logged as a new empty entry, keeping the
  /// note history intact rather than deleting past entries).
  Future<void> clearNote(String babyId, String authorName);

  /// Permanently removes one entry from the note history.
  Future<void> deleteNote(String babyId, String noteId);
}
