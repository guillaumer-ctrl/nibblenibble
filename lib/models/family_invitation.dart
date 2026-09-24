import 'user_role.dart';

enum InvitationStatus { pending, accepted, declined }

/// An outstanding or resolved invite to join a baby's family circle.
/// Per product decision, every invited account defaults to read-only.
class FamilyInvitation {
  const FamilyInvitation({
    required this.id,
    required this.email,
    required this.babyId,
    this.role = UserRole.readOnly,
    this.status = InvitationStatus.pending,
    required this.invitedAt,
  });

  final String id;
  final String email;
  final String babyId;
  final UserRole role;
  final InvitationStatus status;
  final DateTime invitedAt;
}
