import 'package:flutter/material.dart';

import '../models/user_role.dart';
import '../theme/app_theme.dart';

class RoleBadge extends StatelessWidget {
  const RoleBadge({super.key, required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final isAdmin = role == UserRole.admin;
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isAdmin ? colors.sage.withValues(alpha: 0.25) : colors.primaryLight,
        // A small badge, not a button/toggle — sized so AppRadius.card still
        // reads as fully rounded given its short height, without using the
        // button-reserved pill radius.
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Text(
        role.label(context),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isAdmin ? colors.sageDark : colors.inkSoft,
        ),
      ),
    );
  }
}
