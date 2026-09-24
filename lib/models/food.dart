import 'package:flutter/widgets.dart';

import '../l10n/app_strings.dart';

enum FoodCategory {
  legumes,
  fruits,
  feculents,
  viandes,
  poissons,
  herbes,
  epices,
  autre;

  String label(BuildContext context) =>
      AppStrings.of(context).foodCategoryLabel(name);
}

/// A single item from the shared food database (see yummybaby_aliments.xlsx).
class Food {
  const Food({
    required this.id,
    required this.name,
    required this.category,
    this.nameEn,
    this.nameEs,
  });

  final String id;

  /// French name — the database's canonical/original language.
  final String name;
  final FoodCategory category;

  /// English translation, added after the fact for the bilingual UI. Falls
  /// back to [name] if a food was imported before this field existed.
  final String? nameEn;

  /// Spanish translation, added after the fact — same fallback story as
  /// [nameEn]. Falls back to [nameEn], then [name], for foods not yet
  /// translated into Spanish.
  final String? nameEs;

  String displayName(BuildContext context) =>
      displayNameFor(AppStrings.of(context));

  /// Same as [displayName], but for callers (like PDF generation) that
  /// already have an AppStrings instance and no BuildContext to spare.
  String displayNameFor(AppStrings s) {
    if (s.isFrench) return name;
    if (s.isSpanish) return nameEs ?? nameEn ?? name;
    return nameEn ?? name;
  }
}
