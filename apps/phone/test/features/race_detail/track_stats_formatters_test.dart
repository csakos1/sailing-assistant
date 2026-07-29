import 'package:flutter_test/flutter_test.dart';
import 'package:phone/features/race_detail/track_stats_formatters.dart';

void main() {
  group('measureKnots', () {
    test('splits the value from the unit', () {
      // ARRANGE & ACT
      final measured = measureKnots(3.8);

      // ASSERT
      expect(measured.value, '7,4');
      expect(measured.unit, 'kn');
    });

    test('never folds the unit into the value', () {
      // ARRANGE & ACT
      final measured = measureKnots(3.8);

      // ASSERT - a stat-cella ket kulon fokozattal rajzolja a kettot, tehat
      // az ertekben nem lehet benne az egyseg.
      expect(measured.value, isNot(contains('kn')));
      expect(measured.value, isNot(contains(' ')));
    });

    test('uses a decimal comma, never a point', () {
      // ARRANGE & ACT
      final measured = measureKnots(2.6);

      // ASSERT
      expect(measured.value, isNot(contains('.')));
      expect(measured.value, contains(','));
    });

    test('reports a missing reading without a unit', () {
      // ARRANGE & ACT
      final measured = measureKnots(null);

      // ASSERT - a hianyzo meres nem nulla mert ertek, es a mertekegyseg
      // sem all ki egy hianyjel mellett.
      expect(measured.value, missingValueLabel);
      expect(measured.unit, isEmpty);
    });
  });

  group('measureDistance', () {
    test('switches to kilometres above a thousand metres', () {
      // ARRANGE & ACT
      final measured = measureDistance(24600);

      // ASSERT
      expect(measured.value, '24,6');
      expect(measured.unit, 'km');
    });

    test('keeps metres below a thousand, without a decimal', () {
      // ARRANGE & ACT
      final measured = measureDistance(840);

      // ASSERT - egy 840 meteres szakasz `0,8 km` alakban elveszitene a
      // felbontasat.
      expect(measured.value, '840');
      expect(measured.unit, 'm');
      expect(measured.value, isNot(contains(',')));
    });

    test('switches exactly at a thousand metres', () {
      // ARRANGE & ACT
      final measured = measureDistance(1000);

      // ASSERT
      expect(measured.value, '1,0');
      expect(measured.unit, 'km');
    });

    test('reports a missing reading without a unit', () {
      // ARRANGE & ACT
      final measured = measureDistance(null);

      // ASSERT
      expect(measured.value, missingValueLabel);
      expect(measured.unit, isEmpty);
    });
  });

  group('a regi formazokkal valo egyuttelese', () {
    test('keeps the old string formatters untouched', () {
      // ARRANGE & ACT & ASSERT - az export PNG-je meg a regi, pontos
      // alakot hasznalja; azt ez a szelet nem valtja at.
      expect(formatKnots(3.8), '7.4 kn');
      expect(formatDistance(840), '840 m');
      expect(formatDistance(null), missingValueLabel);
    });
  });
}
