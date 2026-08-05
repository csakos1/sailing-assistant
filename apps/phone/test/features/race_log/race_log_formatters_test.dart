import 'package:flutter_test/flutter_test.dart';
import 'package:phone/features/race_log/race_log_formatters.dart';

void main() {
  group('measureHours', () {
    test('reports minutes below one hour', () {
      final measured = measureHours(const Duration(minutes: 45));

      expect(measured.value, '45');
      expect(measured.unit, 'p');
    });

    test('keeps zero as a real measurement, not a gap', () {
      // A Duration.zero valos ertek: nulla percet toltottunk vizen.
      final measured = measureHours(Duration.zero);

      expect(measured.value, '0');
      expect(measured.unit, 'p');
    });

    test('switches to hours at the hour boundary', () {
      final measured = measureHours(const Duration(minutes: 60));

      expect(measured.value, '1,0');
      expect(measured.unit, 'ó');
    });

    test('uses a decimal comma with one digit', () {
      final measured = measureHours(const Duration(minutes: 90));

      expect(measured.value, '1,5');
      expect(measured.unit, 'ó');
    });

    test('rounds a season length to one decimal', () {
      // 42 ora 20 perc = 42,333... -> 42,3
      final measured = measureHours(
        const Duration(hours: 42, minutes: 20),
      );

      expect(measured.value, '42,3');
      expect(measured.unit, 'ó');
    });

    test('drops the unit when the value is missing', () {
      // Egy gondolatjel mellett a mertekegyseg azt sugallna, hogy
      // mertunk valamit.
      final measured = measureHours(null);

      expect(measured.value, '—');
      expect(measured.unit, '');
    });
  });
}
