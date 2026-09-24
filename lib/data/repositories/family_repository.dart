import '../../models/family_member.dart';
import '../../models/family_invitation.dart';
import '../../models/user_role.dart';

abstract class FamilyRepository {
  Stream<List<FamilyMember>> watchMembers(String babyId);
  Future<List<FamilyMember>> getMembers(String babyId);
  Stream<List<FamilyInvitation>> watchInvitations(String babyId);
  Future<void> invite(String babyId, String email, UserRole role);
  Future<void> updateMemberRole(String babyId, String memberId, UserRole role);

  /// Keeps a member's display name in sync across every baby they belong
  /// to — the member doc's `name` is a snapshot taken when they joined
  /// (creator or invite acceptance), so it never updates on its own when
  /// they later rename themselves in Compte.
  Future<void> updateMemberName(String babyId, String memberId, String name);

  Future<void> removeMember(String babyId, String memberId);
  Future<void> cancelInvitation(String babyId, String invitationId);

  /// Pending invitations addressed to [email], across every baby — how a
  /// newly signed-up invitee discovers what they've been invited to.
  Stream<List<FamilyInvitation>> watchMyPendingInvitations(String email);

  Future<void> acceptInvitation(
    FamilyInvitation invitation, {
    required String uid,
    required String name,
    required String email,
  });

  Future<void> declineInvitation(FamilyInvitation invitation);
}
