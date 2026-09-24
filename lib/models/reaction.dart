import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';

/// A baby's reaction to a given food, logged per meal.
///
/// Colors are theme-aware (light/dark tokens differ), so they're exposed as
/// methods taking a [BuildContext] rather than const fields — see
/// [color] and [tint].
enum Reaction {
  aime,
  mitige,
  pasAime;

  /// Main color for this reaction's icon/text — deep enough to read.
  Color color(BuildContext context) {
    final c = AppColors.of(context);
    return switch (this) {
      Reaction.aime => c.sage,
      Reaction.mitige => c.amber,
      Reaction.pasAime => c.red,
    };
  }

  /// Soft pastel tint used for backgrounds/borders behind [color].
  Color tint(BuildContext context) {
    final c = AppColors.of(context);
    return switch (this) {
      Reaction.aime => c.sageLight,
      Reaction.mitige => c.amberLight,
      Reaction.pasAime => c.redLight,
    };
  }

  String label(BuildContext context) =>
      AppStrings.of(context).reactionLabel(name);
}
