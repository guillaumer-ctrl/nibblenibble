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

  /// Tint used for backgrounds/borders behind [color] — callers apply their
  /// own alpha (a soft wash for fills, closer to opaque for borders).
  ///
  /// This used to return the theme's dedicated `sageLight`/`amberLight`/
  /// `redLight` tokens, but those are tuned for solid decorative fills
  /// (e.g. the blob behind [WelcomeScreen]) and are near-black in dark
  /// mode, so an alpha-blended chip built from them was nearly invisible
  /// against the dark background. [color] itself is already a bright,
  /// theme-adjusted tone in dark mode, so it reads correctly at any alpha
  /// in both themes.
  Color tint(BuildContext context) => color(context);

  String label(BuildContext context) =>
      AppStrings.of(context).reactionLabel(name);
}
