import 'package:flutter/widgets.dart';

import '../l10n/app_strings.dart';

/// Access level a family member has on a given baby profile.
enum UserRole {
  admin,
  readOnly;

  String label(BuildContext context) =>
      AppStrings.of(context).userRoleLabel(name);
}
