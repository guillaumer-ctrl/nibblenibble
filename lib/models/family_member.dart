import 'user_role.dart';

/// A person with access to the app (parent, grandparent, nanny, ...).
/// Distinct from [BabyProfile] — members act on behalf of babies, they are
/// not tracked themselves. No avatar, per design.
class FamilyMember {
  const FamilyMember({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;

  FamilyMember copyWith({String? name, UserRole? role}) => FamilyMember(
    id: id,
    name: name ?? this.name,
    email: email,
    role: role ?? this.role,
  );
}
