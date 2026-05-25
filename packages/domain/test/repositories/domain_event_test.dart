import 'package:domain/src/entities/wind_data.dart';
import 'package:domain/src/repositories/domain_event.dart';
import 'package:domain/src/value_objects/angle.dart';
import 'package:domain/src/value_objects/bearing.dart';
import 'package:domain/src/value_objects/coordinate.dart';
import 'package:domain/src/value_objects/speed.dart';
import 'package:test/test.dart';

void main() {
  final timestamp = DateTime.utc(2025, 6, 1, 12, 30, 45);

  WindData buildWindData() => WindData(
    apparentAngle: const Angle(degrees: 35),
    apparentSpeed: const Speed(metersPerSecond: 6),
    timestamp: timestamp,
  );

  group('DomainEvent', () {
    group('WindEvent', () {
      test('a timestamp a WindData-ból öröklődik', () {
        // Arrange
        final data = buildWindData();

        // Act
        final event = WindEvent(data);

        // Assert
        expect(event.data, equals(data));
        expect(event.timestamp, equals(timestamp));
      });

      test('azonos WindData → egyenlő', () {
        expect(WindEvent(buildWindData()), equals(WindEvent(buildWindData())));
      });
    });

    test('PositionEvent mezője és timestamp-je elérhető', () {
      const position = Coordinate(latitude: 46.9, longitude: 17.9);

      final event = PositionEvent(position, timestamp);

      expect(event.position, equals(position));
      expect(event.timestamp, equals(timestamp));
    });

    test('HeadingEvent a magneticNorth headinget hordozza', () {
      const heading = Bearing(
        degrees: 120,
        reference: BearingReference.magneticNorth,
      );

      final event = HeadingEvent(heading, timestamp);

      expect(event.heading, equals(heading));
      expect(event.timestamp, equals(timestamp));
    });

    group('CogSogEvent', () {
      const cog = Bearing(degrees: 125, reference: BearingReference.trueNorth);
      const sog = Speed(metersPerSecond: 5);

      test('mezői elérhetők', () {
        final event = CogSogEvent(cog, sog, timestamp);

        expect(event.courseOverGround, equals(cog));
        expect(event.speedOverGround, equals(sog));
        expect(event.timestamp, equals(timestamp));
      });

      test('azonos mezők → egyenlő, eltérő SOG → nem egyenlő', () {
        expect(
          CogSogEvent(cog, sog, timestamp),
          equals(CogSogEvent(cog, sog, timestamp)),
        );
        expect(
          CogSogEvent(cog, sog, timestamp),
          isNot(
            equals(
              CogSogEvent(cog, const Speed(metersPerSecond: 6), timestamp),
            ),
          ),
        );
      });
    });

    test('SpeedEvent a vízsebességet hordozza', () {
      const stw = Speed(metersPerSecond: 4.8);

      final event = SpeedEvent(stw, timestamp);

      expect(event.speedThroughWater, equals(stw));
      expect(event.timestamp, equals(timestamp));
    });

    test('eltérő leaf-típus sosem egyenlő', () {
      final position = PositionEvent(
        const Coordinate(latitude: 46.9, longitude: 17.9),
        timestamp,
      );
      final heading = HeadingEvent(
        const Bearing(degrees: 120, reference: BearingReference.magneticNorth),
        timestamp,
      );

      expect(position, isNot(equals(heading)));
    });
  });
}
