import 'package:flutter_test/flutter_test.dart';
import 'package:nibblenibble/models/baby_profile.dart';

void main() {
  group('BabyProfile.diversificationDays', () {
    test('is null when diversification has not started', () {
      final baby = BabyProfile(
        id: '1',
        name: 'Léo',
        birthDate: DateTime.now().subtract(const Duration(days: 200)),
      );
      expect(baby.diversificationDays, isNull);
    });

    test('counts days since diversification started', () {
      final baby = BabyProfile(
        id: '1',
        name: 'Léo',
        birthDate: DateTime.now().subtract(const Duration(days: 200)),
        diversificationStartDate: DateTime.now().subtract(
          const Duration(days: 10),
        ),
      );
      expect(baby.diversificationDays, 10);
    });
  });

  group('BabyProfile.ageInMonths', () {
    test('computes whole months from the birth date', () {
      final now = DateTime.now();
      final birthDate = DateTime(now.year, now.month - 6, now.day);
      final baby = BabyProfile(id: '1', name: 'Léo', birthDate: birthDate);
      expect(baby.ageInMonths, 6);
    });
  });
}
