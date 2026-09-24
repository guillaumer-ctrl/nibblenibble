import 'package:flutter/widgets.dart';

import '../l10n/app_strings.dart';

enum BabyGender {
  fille,
  garcon,
  nonPrecise;

  String label(BuildContext context) =>
      AppStrings.of(context).babyGenderLabel(name);
}

/// A baby being tracked.
class BabyProfile {
  const BabyProfile({
    required this.id,
    required this.name,
    required this.birthDate,
    this.diversificationStartDate,
    this.gender = BabyGender.nonPrecise,
  });

  final String id;
  final String name;
  final DateTime birthDate;

  /// When food diversification began for this baby. Null until the family
  /// logs the first meal, at which point it should be set.
  final DateTime? diversificationStartDate;

  final BabyGender gender;

  int get ageInMonths {
    final now = DateTime.now();
    return (now.year - birthDate.year) * 12 + now.month - birthDate.month;
  }

  int? get diversificationDays => diversificationStartDate == null
      ? null
      : DateTime.now().difference(diversificationStartDate!).inDays;
}
