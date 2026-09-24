import 'package:flutter_test/flutter_test.dart';
import 'package:nibblenibble/utils/diacritics.dart';

void main() {
  group('foldDiacritics', () {
    test('strips common French accents', () {
      expect(foldDiacritics('épinard'), 'epinard');
      expect(foldDiacritics('crème'), 'creme');
      expect(foldDiacritics('pêche'), 'peche');
      expect(foldDiacritics('à'), 'a');
      expect(foldDiacritics('œuf'), 'oeuf');
    });

    test('leaves plain text untouched', () {
      expect(foldDiacritics('poulet'), 'poulet');
      expect(foldDiacritics(''), '');
    });

    test('an unaccented search term matches accented food names', () {
      // Regression for: searching "e" didn't surface "épinard" because the
      // query and the food name were compared without folding either side.
      final folded = foldDiacritics('épinard'.toLowerCase());
      expect(folded.contains(foldDiacritics('e')), isTrue);
    });
  });
}
