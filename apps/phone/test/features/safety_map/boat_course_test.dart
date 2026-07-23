import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/features/safety_map/boat_course.dart';

void main() {
  BoatState boat({Bearing? course, Speed? speed}) => BoatState(
    lastUpdate: DateTime.utc(2026, 7),
    courseOverGround: course,
    speedOverGround: speed,
  );

  const east = Bearing.true_(90);

  group('usableCourseOverGround', () {
    test('a kuszob folott a COG-ot adja', () {
      // ARRANGE + ACT
      final course = usableCourseOverGround(
        boat(course: east, speed: const Speed(metersPerSecond: 3)),
      );

      // ASSERT
      expect(course, isNotNull);
      expect(course!.degrees, 90);
      expect(course.reference, BearingReference.trueNorth);
    });

    test('pontosan a kuszobon meg rajzol', () {
      // ARRANGE + ACT -- a hatar BENNE van; egy szigoru > eseten ez bukna.
      final course = usableCourseOverGround(
        boat(course: east, speed: boatCourseMinSpeed),
      );

      // ASSERT
      expect(course, isNotNull);
    });

    test('a kuszob alatt nincs irany', () {
      // ARRANGE
      const crawling = Speed(
        metersPerSecond: 0.5,
      );

      // ACT + ASSERT -- kis sebessegnel a COG zaj (D12).
      expect(
        usableCourseOverGround(boat(course: east, speed: crawling)),
        isNull,
      );
    });

    test('COG nelkul nincs irany', () {
      // ACT + ASSERT
      expect(
        usableCourseOverGround(
          boat(speed: const Speed(metersPerSecond: 5)),
        ),
        isNull,
      );
    });

    test('SOG nelkul nincs irany', () {
      // ACT + ASSERT -- sebesseg nelkul nem tudjuk megitelni a COG-ot.
      expect(usableCourseOverGround(boat(course: east)), isNull);
    });

    test('ures allapotra nincs irany', () {
      // ACT + ASSERT
      expect(usableCourseOverGround(boat()), isNull);
    });

    test('a kuszob 1 csomo korul all', () {
      // ASSERT -- a konstans erteket rogziti, hogy egy veletlen elirast
      // eszrevegyunk. 1 kn = 0.5144 m/s.
      expect(boatCourseMinSpeed.metersPerSecond, closeTo(0.5144, 1e-9));
    });
  });
}
