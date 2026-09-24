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

  /// Whole calendar days elapsed since [diversificationStartDate], not a
  /// raw 24h-duration count — the old `DateTime.now().difference(...)`
  /// compared exact timestamps, so the count only advanced at the
  /// time-of-day the first meal happened to be logged (e.g. logged at
  /// 21:00 on day 1: still showed the same number until 21:00 the next
  /// day) instead of at midnight, drifting up to a day behind the actual
  /// calendar date a parent would count by hand.
  int? get diversificationDays {
    final start = diversificationStartDate;
    if (start == null) return null;
    final startDate = DateTime(start.year, start.month, start.day);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return today.difference(startDate).inDays;
  }
}
