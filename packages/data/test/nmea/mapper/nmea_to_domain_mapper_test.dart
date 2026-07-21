import 'package:data/src/nmea/mapper/nmea_to_domain_mapper.dart';
import 'package:data/src/nmea/parser/decoded_sentence.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const awa = Angle(degrees: 30);
  const aws = Speed(metersPerSecond: 5);
  const twa = Angle(degrees: 40);
  const tws = Speed(metersPerSecond: 7);
  const twd = Bearing.true_(210);
  const cog = Bearing.true_(95);
  const sog = Speed(metersPerSecond: 3);
  const heading = Bearing.magnetic_(120);
  const stw = Speed(metersPerSecond: 4);
  const position = Coordinate(latitude: 46.9, longitude: 18.03);

  final now = DateTime.utc(2025, 6, 1, 12);
  final now2 = DateTime.utc(2025, 6, 1, 12, 0, 1);
  final instrumentUtc = DateTime.utc(2025, 6, 1, 11, 59, 58);

  group('NmeaToDomainMapper egyszerű leképezések', () {
    test('DecodedPosition → PositionEvent', () {
      // ARRANGE
      final mapper = NmeaToDomainMapper();

      // ACT
      final events = mapper.map(
        const DecodedPosition(position: position),
        now,
      );

      // ASSERT
      expect(events, equals([PositionEvent(position, now)]));
    });

    test('DecodedCogSog → CogSogEvent', () {
      final mapper = NmeaToDomainMapper();

      final events = mapper.map(
        const DecodedCogSog(courseOverGround: cog, speedOverGround: sog),
        now,
      );

      expect(events, equals([CogSogEvent(cog, sog, now)]));
    });

    test('DecodedHeading → HeadingEvent', () {
      final mapper = NmeaToDomainMapper();

      final events = mapper.map(const DecodedHeading(heading: heading), now);

      expect(events, equals([HeadingEvent(heading, now)]));
    });

    test('DecodedHeading + headingTrue → magnetic + true HeadingEvent', () {
      final mapper = NmeaToDomainMapper();
      const headingTrue = Bearing.true_(125);

      final events = mapper.map(
        const DecodedHeading(heading: heading, headingTrue: headingTrue),
        now,
      );

      expect(
        events,
        equals([HeadingEvent(heading, now), HeadingEvent(headingTrue, now)]),
      );
    });

    test('DecodedSpeed → SpeedEvent', () {
      final mapper = NmeaToDomainMapper();

      final events = mapper.map(
        const DecodedSpeed(speedThroughWater: stw),
        now,
      );

      expect(events, equals([SpeedEvent(stw, now)]));
    });
  });

  group('NmeaToDomainMapper RMC kompozit', () {
    test('DecodedRmc → Position + CogSog (now) + InstrumentTime (UTC)', () {
      final mapper = NmeaToDomainMapper();

      final events = mapper.map(
        DecodedRmc(
          position: position,
          courseOverGround: cog,
          speedOverGround: sog,
          timestampUtc: instrumentUtc,
        ),
        now,
      );

      // Sorrend + időbélyeg-politika egyben: az első kettő now, a
      // harmadik a GPS-instant.
      expect(
        events,
        equals([
          PositionEvent(position, now),
          CogSogEvent(cog, sog, now),
          InstrumentTimeEvent(instrumentUtc),
        ]),
      );
    });
  });

  group('NmeaToDomainMapper szél apparent-gate', () {
    test('apparent szél → WindEvent apparent mezőkkel', () {
      final mapper = NmeaToDomainMapper();

      final events = mapper.map(
        const DecodedWind(
          reference: WindReference.apparent,
          angle: awa,
          speed: aws,
        ),
        now,
      );

      final expected = WindData(
        apparentAngle: awa,
        apparentSpeed: aws,
        timestamp: now,
      );
      expect(events, equals([WindEvent(expected)]));
    });

    test('true szél apparent előtt → üres lista', () {
      final mapper = NmeaToDomainMapper();

      final events = mapper.map(
        const DecodedWind(
          reference: WindReference.true_,
          angle: twa,
          speed: tws,
        ),
        now,
      );

      expect(events, isEmpty);
    });

    test('MWD (TWD) apparent előtt → üres lista', () {
      final mapper = NmeaToDomainMapper();

      final events = mapper.map(
        const DecodedWindDirection(direction: twd, speed: tws),
        now,
      );

      expect(events, isEmpty);
    });
  });

  group('NmeaToDomainMapper szél stateful aggregálás', () {
    test('apparent után a true szél WindEvent-et ad', () {
      // ARRANGE: két külön map() hívás, közös aggregátor-állapot.
      final mapper = NmeaToDomainMapper()
        ..map(
          const DecodedWind(
            reference: WindReference.apparent,
            angle: awa,
            speed: aws,
          ),
          now,
        );

      // ACT
      final events = mapper.map(
        const DecodedWind(
          reference: WindReference.true_,
          angle: twa,
          speed: tws,
        ),
        now2,
      );

      // ASSERT: a snapshot a stale apparent-et és a friss true-water-t is
      // hordozza, a now2 időbélyeggel.
      final expected = WindData(
        apparentAngle: awa,
        apparentSpeed: aws,
        trueAngleWater: twa,
        trueSpeedWater: tws,
        timestamp: now2,
      );
      expect(events, equals([WindEvent(expected)]));
    });

    test('apparent után az MWD WindEvent-et ad TWD-vel', () {
      final mapper = NmeaToDomainMapper()
        ..map(
          const DecodedWind(
            reference: WindReference.apparent,
            angle: awa,
            speed: aws,
          ),
          now,
        );

      final events = mapper.map(
        const DecodedWindDirection(direction: twd, speed: tws),
        now2,
      );

      final expected = WindData(
        apparentAngle: awa,
        apparentSpeed: aws,
        trueDirectionGround: twd,
        timestamp: now2,
      );
      expect(events, equals([WindEvent(expected)]));
    });
  });

  group('NmeaToDomainMapper mélység forrás-gate', () {
    const dbtDepth = Depth(meters: 3);
    // A DPT bizonyítottan hibás diszkrét értéke a mért dumpból: a 2,5 m-es
    // riasztási küszöb ALATT van, ezért nem szabad nyernie.
    const dptDepth = Depth(meters: 2);

    const dbtSentence = DecodedDepth(depth: dbtDepth, source: DepthSource.dbt);
    const dptSentence = DecodedDepth(depth: dptDepth, source: DepthSource.dpt);

    test('DecodedDepth (DBT) → DepthEvent', () {
      // ARRANGE
      final mapper = NmeaToDomainMapper();

      // ACT
      final events = mapper.map(dbtSentence, now);

      // ASSERT
      expect(events, equals([DepthEvent(dbtDepth, now)]));
    });

    test('a DBT után érkező DPT elnyomva (interleaving)', () {
      // ARRANGE: a valós stream sorrendje — a DPT közvetlenül a DBT után,
      // ugyanabban a másodpercben.
      final mapper = NmeaToDomainMapper()..map(dbtSentence, now);

      // ACT
      final events = mapper.map(dptSentence, now);

      // ASSERT: gate nélkül ez írná felül a BoatState.depth-et (last-wins).
      expect(events, isEmpty);
    });

    test('DPT egyedüli forrásként azonnal emittál', () {
      final mapper = NmeaToDomainMapper();

      final events = mapper.map(dptSentence, now);

      expect(events, equals([DepthEvent(dptDepth, now)]));
    });

    test('a DBT elnémulása után a DPT átveszi', () {
      final mapper = NmeaToDomainMapper()..map(dbtSentence, now);
      final afterWindow = now.add(const Duration(seconds: 5));

      final events = mapper.map(dptSentence, afterWindow);

      expect(events, equals([DepthEvent(dptDepth, afterWindow)]));
    });

    test('a DBT visszatérése újra elnyomja a DPT-t', () {
      final afterWindow = now.add(const Duration(seconds: 5));
      final mapper = NmeaToDomainMapper()
        ..map(dbtSentence, now)
        ..map(dbtSentence, afterWindow);

      final events = mapper.map(dptSentence, afterWindow);

      expect(events, isEmpty);
    });
  });
}
