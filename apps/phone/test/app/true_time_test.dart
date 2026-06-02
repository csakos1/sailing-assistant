import 'package:flutter_test/flutter_test.dart';
import 'package:phone/app/true_time.dart';

void main() {
  group('extrapolate', () {
    test('a monoton eltelt időt adja az anchorhoz, UTC marad', () {
      // ARRANGE
      final anchor = DateTime.utc(2026, 5, 24, 9, 6, 47);

      // ACT
      final result = extrapolate(anchor, const Duration(seconds: 5));

      // ASSERT
      expect(result, DateTime.utc(2026, 5, 24, 9, 6, 52));
      expect(result.isUtc, isTrue);
    });

    test('nulla eltelt idő → maga az anchor', () {
      final anchor = DateTime.utc(2026, 5, 24, 9, 6, 47);
      expect(extrapolate(anchor, Duration.zero), anchor);
    });
  });

  group('resolveAnchor', () {
    final wall = DateTime.utc(2026, 5, 24, 11);
    final fix = DateTime.utc(2026, 5, 24, 9, 6, 47);

    test('friss fix → GNSS-anchor a fix UTC-jén', () {
      // ACT
      final result = resolveAnchor(
        fixUtc: fix,
        wallClockUtc: wall,
        current: null,
      );

      // ASSERT
      expect(
        result,
        TrueTimeAnchor(anchorUtc: fix, source: TrueTimeSource.gnss),
      );
    });

    test('friss fix felülír egy korábbi anchort', () {
      final old = TrueTimeAnchor(
        anchorUtc: DateTime.utc(2026, 5, 24, 8),
        source: TrueTimeSource.sessionAnchor,
      );
      final result = resolveAnchor(
        fixUtc: fix,
        wallClockUtc: wall,
        current: old,
      );
      expect(
        result,
        TrueTimeAnchor(anchorUtc: fix, source: TrueTimeSource.gnss),
      );
    });

    test('nincs fix, volt GNSS → sessionAnchor, a régi anchorUtc marad', () {
      final current = TrueTimeAnchor(
        anchorUtc: fix,
        source: TrueTimeSource.gnss,
      );
      final result = resolveAnchor(
        fixUtc: null,
        wallClockUtc: wall,
        current: current,
      );
      expect(
        result,
        TrueTimeAnchor(anchorUtc: fix, source: TrueTimeSource.sessionAnchor),
      );
    });

    test('nincs fix, sessionAnchor → marad, anchorUtc marad', () {
      final current = TrueTimeAnchor(
        anchorUtc: fix,
        source: TrueTimeSource.sessionAnchor,
      );
      final result = resolveAnchor(
        fixUtc: null,
        wallClockUtc: wall,
        current: current,
      );
      expect(
        result,
        TrueTimeAnchor(anchorUtc: fix, source: TrueTimeSource.sessionAnchor),
      );
    });

    test('nincs fix, sosem volt → wallClockUnsynced a telefon-órán', () {
      final result = resolveAnchor(
        fixUtc: null,
        wallClockUtc: wall,
        current: null,
      );
      expect(
        result,
        TrueTimeAnchor(
          anchorUtc: wall,
          source: TrueTimeSource.wallClockUnsynced,
        ),
      );
    });

    test(
      'nincs fix, korábbi wallClockUnsynced → friss telefon-órára újra-seed',
      () {
        final current = TrueTimeAnchor(
          anchorUtc: DateTime.utc(2026, 5, 24, 10),
          source: TrueTimeSource.wallClockUnsynced,
        );
        final result = resolveAnchor(
          fixUtc: null,
          wallClockUtc: wall,
          current: current,
        );
        expect(
          result,
          TrueTimeAnchor(
            anchorUtc: wall,
            source: TrueTimeSource.wallClockUnsynced,
          ),
        );
      },
    );
  });

  group('TrueTimeAnchor.readingAfter', () {
    test('a reading az extrapolált UTC + a forrás', () {
      final anchor = TrueTimeAnchor(
        anchorUtc: DateTime.utc(2026, 5, 24, 9, 6, 47),
        source: TrueTimeSource.gnss,
      );
      final reading = anchor.readingAfter(const Duration(seconds: 3));
      expect(
        reading,
        TrueTimeReading(
          utc: DateTime.utc(2026, 5, 24, 9, 6, 50),
          source: TrueTimeSource.gnss,
        ),
      );
    });
  });
}
