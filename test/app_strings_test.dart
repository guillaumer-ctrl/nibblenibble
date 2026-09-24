import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nibblenibble/l10n/app_strings.dart';

void main() {
  test('picks the French string for a French locale', () {
    const s = AppStrings(Locale('fr', 'FR'));
    expect(s.isFrench, isTrue);
    expect(s.cancel, 'Annuler');
  });

  test('picks the English string for an English locale', () {
    const s = AppStrings(Locale('en', 'US'));
    expect(s.isFrench, isFalse);
    expect(s.cancel, 'Cancel');
  });
}
