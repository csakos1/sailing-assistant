import 'package:flutter_test/flutter_test.dart';
import 'package:phone/features/web_access/application/hungarian_order.dart';

void main() {
  List<String> sorted(List<String> names) => [...names]..sort(compareHungarian);

  group('compareHungarian', () {
    test('accented letters come right after their base letter', () {
      expect(sorted(['Zoli', 'Ádám', 'Bence', 'Andi']), [
        'Andi',
        'Ádám',
        'Bence',
        'Zoli',
      ]);
      expect(sorted(['Ödön', 'Ottó', 'Őrs', 'Pál']), [
        'Ottó',
        'Ödön',
        'Őrs',
        'Pál',
      ]);
    });

    test('case does not matter', () {
      expect(sorted(['bence', 'Ádám', 'anna']), ['anna', 'Ádám', 'bence']);
    });

    test('a shorter prefix and a space come first', () {
      expect(sorted(['Kisó', 'Kis Ádám', 'Kis']), ['Kis', 'Kis Ádám', 'Kisó']);
    });

    test('equal letters fall back to the code points', () {
      expect(compareHungarian('Dori', 'dori'), lessThan(0));
      expect(compareHungarian('Dori', 'Dori'), 0);
    });
  });
}
