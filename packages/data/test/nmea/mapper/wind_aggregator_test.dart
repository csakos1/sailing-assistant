import 'package:data/src/nmea/mapper/wind_aggregator.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const awa = Angle(degrees: 35);
  const aws = Speed(metersPerSecond: 4);
  const twaWater = Angle(degrees: 42);
  const twsWater = Speed(metersPerSecond: 6);
  const twd = Bearing.true_(220);
  final t1 = DateTime.utc(2025, 6, 1, 10);
  final t2 = DateTime.utc(2025, 6, 1, 10, 0, 1);
  final t3 = DateTime.utc(2025, 6, 1, 10, 0, 2);

  group('WindAggregator apparent-gate', () {
    test('apparent előtt applyTrueWater null-t ad', () {
      // ARRANGE
      final aggregator = WindAggregator();

      // ACT
      final result = aggregator.applyTrueWater(twaWater, twsWater, t1);

      // ASSERT
      expect(result, isNull);
    });

    test('apparent előtt applyTrueDirection null-t ad', () {
      final aggregator = WindAggregator();

      final result = aggregator.applyTrueDirection(twd, t1);

      expect(result, isNull);
    });

    test('apparent előtti true-water apparent után megjelenik', () {
      // A gate előtt érkező true-water "elveszett" (null volt), de az
      // aggregátor eltárolta a mezőt — apparent után már látszik.
      final aggregator = WindAggregator()
        ..applyTrueWater(twaWater, twsWater, t1);

      final result = aggregator.applyApparent(awa, aws, t2);

      expect(result.trueAngleWater, equals(twaWater));
      expect(result.trueSpeedWater, equals(twsWater));
    });
  });

  group('WindAggregator snapshot tartalom', () {
    test('első apparent: csak apparent mezők, true-k null', () {
      final aggregator = WindAggregator();

      final result = aggregator.applyApparent(awa, aws, t1);

      expect(result.apparentAngle, equals(awa));
      expect(result.apparentSpeed, equals(aws));
      expect(result.trueAngleWater, isNull);
      expect(result.trueSpeedWater, isNull);
      expect(result.trueDirectionGround, isNull);
      expect(result.hasTrueWind, isFalse);
    });

    test('apparent után true-water: apparent + true-water mezők', () {
      final aggregator = WindAggregator()..applyApparent(awa, aws, t1);

      final result = aggregator.applyTrueWater(twaWater, twsWater, t2);

      switch (result) {
        case null:
          fail('apparent után a snapshot nem lehet null');
        case final WindData wind:
          expect(wind.apparentAngle, equals(awa));
          expect(wind.trueAngleWater, equals(twaWater));
          expect(wind.trueSpeedWater, equals(twsWater));
          expect(wind.trueDirectionGround, isNull);
      }
    });

    test('apparent után TWD: apparent + TWD mező', () {
      final aggregator = WindAggregator()..applyApparent(awa, aws, t1);

      final result = aggregator.applyTrueDirection(twd, t2);

      switch (result) {
        case null:
          fail('apparent után a snapshot nem lehet null');
        case final WindData wind:
          expect(wind.trueDirectionGround, equals(twd));
          expect(wind.apparentAngle, equals(awa));
      }
    });

    test('teljes szekvencia: minden mező feltöltődik', () {
      final aggregator = WindAggregator()
        ..applyApparent(awa, aws, t1)
        ..applyTrueWater(twaWater, twsWater, t2);

      final result = aggregator.applyTrueDirection(twd, t3);

      switch (result) {
        case null:
          fail('a teljes szekvencia végén a snapshot nem lehet null');
        case final WindData wind:
          expect(wind.apparentAngle, equals(awa));
          expect(wind.apparentSpeed, equals(aws));
          expect(wind.trueAngleWater, equals(twaWater));
          expect(wind.trueSpeedWater, equals(twsWater));
          expect(wind.trueDirectionGround, equals(twd));
          expect(wind.hasTrueWind, isTrue);
      }
    });
  });

  group('WindAggregator stale-megőrzés és felülírás', () {
    test('új apparent felülír, true mezőket megtart', () {
      final aggregator = WindAggregator()
        ..applyApparent(awa, aws, t1)
        ..applyTrueWater(twaWater, twsWater, t2);

      const newAwa = Angle(degrees: -50);
      const newAws = Speed(metersPerSecond: 7);
      final result = aggregator.applyApparent(newAwa, newAws, t3);

      expect(result.apparentAngle, equals(newAwa));
      expect(result.apparentSpeed, equals(newAws));
      // A true-water mezők nem nulláznak az új apparent-tel.
      expect(result.trueAngleWater, equals(twaWater));
      expect(result.trueSpeedWater, equals(twsWater));
    });
  });

  group('WindAggregator timestamp', () {
    test('a snapshot a hívásban kapott now-t hordozza', () {
      final aggregator = WindAggregator()..applyApparent(awa, aws, t1);

      final first = aggregator.applyApparent(awa, aws, t1);
      final second = aggregator.applyTrueWater(twaWater, twsWater, t2);

      expect(first.timestamp, equals(t1));
      expect(second?.timestamp, equals(t2));
    });
  });
}
