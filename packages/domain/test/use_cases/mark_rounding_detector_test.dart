import 'dart:math' show pi;

import 'package:domain/src/entities/mark.dart';
import 'package:domain/src/use_cases/mark_rounding_detector.dart';
import 'package:domain/src/value_objects/coordinate.dart';
import 'package:test/test.dart';

void main() {
  group('MarkRoundingDetector', () {
    // Meridián mentén (Δlon = 0) a Haversine pontosan R·Δlat, ezért egy
    // adott méternyi lat-eltolás pontosan annyi méter távolságot ad a
    // bóyától (R = 6371000, ugyanaz mint a CalculateDistanceToMark-ban).
    const metersPerDegLat = 6371000 * pi / 180; // ≈ 111194.93 m/fok
    const markLat = 46.9;
    const markLon = 18.0;
    const mark = Mark(
      sequence: 1,
      name: 'Z1',
      position: Coordinate(latitude: markLat, longitude: markLon),
    );

    // A bóyától északra `metersNorth` méterre lévő hajópozíció.
    Coordinate boatAt(double metersNorth) => Coordinate(
      latitude: markLat + metersNorth / metersPerDegLat,
      longitude: markLon,
    );

    test('első tick → false (nincs korábbi minimum)', () {
      final detector = MarkRoundingDetector();

      expect(detector.tick(boatAt(100), mark), isFalse);
    });

    test('monoton közeledés → végig false', () {
      final detector = MarkRoundingDetector();

      expect(detector.tick(boatAt(100), mark), isFalse);
      expect(detector.tick(boatAt(60), mark), isFalse);
      expect(detector.tick(boatAt(20), mark), isFalse);
      expect(detector.tick(boatAt(5), mark), isFalse);
    });

    test('küszöbön belül megközelít, majd hiszterézist meghaladva '
        'távolodik → true', () {
      final detector = MarkRoundingDetector();

      expect(detector.tick(boatAt(40), mark), isFalse);
      expect(detector.tick(boatAt(10), mark), isFalse);
      // 12 m: 2 m távolodás < 5 m hiszterézis → még false.
      expect(detector.tick(boatAt(12), mark), isFalse);
      // 20 m: 10 m távolodás > 5 m → ROUNDED.
      expect(detector.tick(boatAt(20), mark), isTrue);
    });

    test('csak a hiszterézisen belül távolodik → false (jitter elnyomás)', () {
      final detector = MarkRoundingDetector();

      expect(detector.tick(boatAt(30), mark), isFalse);
      expect(detector.tick(boatAt(10), mark), isFalse);
      // 13 m: 3 m távolodás < 5 m → nem trigger.
      expect(detector.tick(boatAt(13), mark), isFalse);
    });

    test('sosem volt 50 m-en belül → távolodáskor sem true', () {
      final detector = MarkRoundingDetector();

      // Legközelebb 80 m (> 50 m küszöb).
      expect(detector.tick(boatAt(120), mark), isFalse);
      expect(detector.tick(boatAt(80), mark), isFalse);
      expect(detector.tick(boatAt(200), mark), isFalse);
    });

    test('re-approach: részleges távolodás, majd újra közeledés → '
        'min frissül, nincs téves trigger', () {
      final detector = MarkRoundingDetector();

      expect(detector.tick(boatAt(40), mark), isFalse);
      expect(detector.tick(boatAt(10), mark), isFalse);
      // Hiszterézisen belül → false.
      expect(detector.tick(boatAt(13), mark), isFalse);
      // Újra közeledünk 4 m-ig → min frissül.
      expect(detector.tick(boatAt(4), mark), isFalse);
      // 12 m: 8 m távolodás az új 4 m-es minimumtól > 5 m → ROUNDED.
      expect(detector.tick(boatAt(12), mark), isTrue);
    });

    test('level-trigger: a feltétel fennállásáig minden tick true', () {
      final detector = MarkRoundingDetector();

      expect(detector.tick(boatAt(10), mark), isFalse);
      expect(detector.tick(boatAt(20), mark), isTrue);
      // Tovább távolodva is true — a reset a consumer dolga.
      expect(detector.tick(boatAt(40), mark), isTrue);
    });

    test('reset() friss állapotot ad — a korábbi minimum elfelejtődik', () {
      final detector = MarkRoundingDetector();

      expect(detector.tick(boatAt(10), mark), isFalse);
      expect(detector.tick(boatAt(20), mark), isTrue);

      detector.reset();

      // Reset után újra a nulláról egy teljes ciklus.
      expect(detector.tick(boatAt(30), mark), isFalse);
      expect(detector.tick(boatAt(8), mark), isFalse);
      expect(detector.tick(boatAt(20), mark), isTrue);
    });
  });
}
