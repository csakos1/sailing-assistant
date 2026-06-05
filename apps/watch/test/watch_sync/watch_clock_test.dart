import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';
import 'package:watch/watch_sync/gps_clock_reading.dart';
import 'package:watch/watch_sync/watch_clock.dart';

void main() {
  // Megbízható payload az adott UTC-vel (a többi mező a teszthez közömbös).
  WatchPayload trusted(DateTime utc) =>
      WatchPayload(timestamp: utc, gpsTimeUtc: utc, isGpsTimeTrusted: true);

  group('GpsClockReading', () {
    test('untrusted has no time and is not trusted', () {
      // Arrange / Act
      const reading = GpsClockReading.untrusted();

      // Assert
      expect(reading.displayUtc, isNull);
      expect(reading.isTrusted, isFalse);
    });

    test('value equality', () {
      // Arrange / Act
      final a = GpsClockReading(
        displayUtc: DateTime.utc(2026, 6, 2, 10),
        isTrusted: true,
      );
      final b = GpsClockReading(
        displayUtc: DateTime.utc(2026, 6, 2, 10),
        isTrusted: true,
      );

      // Assert
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });

  group('WatchClock', () {
    test('reads untrusted before any payload', () {
      // Arrange
      final clock = WatchClock(monotonic: () => Duration.zero);

      // Act / Assert
      expect(clock.read(), const GpsClockReading.untrusted());
    });

    test('anchors a trusted payload and extrapolates by monotonic elapsed', () {
      // Arrange — a fake monoton forrás eltelt ideje kézzel léptetve.
      var elapsed = Duration.zero;
      final clock = WatchClock(monotonic: () => elapsed);
      final anchor = DateTime.utc(2026, 6, 2, 10, 30);
      clock.onPayload(trusted(anchor));

      // Act — 3 mp telt el a horgony óta.
      elapsed = const Duration(seconds: 3);
      final reading = clock.read();

      // Assert
      expect(reading.isTrusted, isTrue);
      expect(
        reading.displayUtc,
        equals(anchor.add(const Duration(seconds: 3))),
      );
    });

    test('re-anchors on a newer payload and resets the elapsed origin', () {
      // Arrange — a horgony rögzítése a konstruktorra fűzve (cascade).
      var elapsed = Duration.zero;
      final clock = WatchClock(monotonic: () => elapsed)
        ..onPayload(trusted(DateTime.utc(2026, 6, 2, 10, 30)));

      // Act — 10 mp múlva friss fix érkezik, onnan még 2 mp telik el.
      elapsed = const Duration(seconds: 10);
      final fresh = DateTime.utc(2026, 6, 2, 10, 30, 9);
      clock.onPayload(trusted(fresh));
      elapsed = const Duration(seconds: 12);

      // Assert — az új horgonytól számol (fresh + 2 mp), nem a régitől.
      expect(
        clock.read().displayUtc,
        equals(fresh.add(const Duration(seconds: 2))),
      );
    });

    test('clears the anchor when the payload is not trusted', () {
      // Arrange — előbb megbízható horgony, majd egy nem megbízható payload
      // (alapból isGpsTimeTrusted == false) törli; cascade a konstruktorra.
      final clock = WatchClock(monotonic: () => Duration.zero)
        ..onPayload(trusted(DateTime.utc(2026, 6, 2, 10, 30)))
        ..onPayload(
          WatchPayload(
            timestamp: DateTime.utc(2026, 6, 2, 10, 30, 1),
            gpsTimeUtc: DateTime.utc(2026, 6, 2, 10, 30, 1),
          ),
        );

      // Assert
      expect(clock.read().isTrusted, isFalse);
    });

    test('clears the anchor when gpsTimeUtc is null', () {
      // Arrange — trusted, de gpsTimeUtc nélkül → nincs mit görgetni.
      final clock = WatchClock(monotonic: () => Duration.zero)
        ..onPayload(trusted(DateTime.utc(2026, 6, 2, 10, 30)))
        ..onPayload(
          WatchPayload(
            timestamp: DateTime.utc(2026, 6, 2, 10, 30, 1),
            isGpsTimeTrusted: true,
          ),
        );

      // Assert
      expect(clock.read().isTrusted, isFalse);
    });
  });
}
