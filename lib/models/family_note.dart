/// One entry in a baby's family note history. The most recent entry (by
/// [updatedAt]) is the note shown on the home screen; older ones are the
/// history admins can look back through.
class FamilyNote {
  const FamilyNote({
    required this.id,
    required this.text,
    required this.authorName,
    required this.updatedAt,
  });

  final String id;
  final String text;
  final String authorName;
  final DateTime updatedAt;
}
