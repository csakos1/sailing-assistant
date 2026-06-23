import 'package:shared/shared.dart';
import 'package:test/test.dart';

void main() {
  group('WatchPayload', () {
    final buildTime = DateTime.utc(2026, 6, 2, 10, 30);
    final gpsTime = DateTime.utc(2026, 6, 2, 10, 29, 58);

    // Teljes, props-fedett mintapéldány nem-null értékekkel; az egyes
    // tesztek egy-egy mezőt felülírnak. A vmgKnots szándékosan kimarad
    // (v1-ben mindig null).
    WatchPayload sample({
      DateTime? timestamp,
      DateTime? gpsTimeUtc,
      bool isGpsTimeTrusted = true,
      double sogKnots = 6.4,
      double currentTwa = -42.5,
      double predictedTwaAtMark = 38,
      double forecastBandDegrees = 4.5,
      double courseCorrection = -7.5,
      int etaSeconds = 154,
      double distanceMeters = 480,
      String markName = 'Tihany bója',
      double targetSpeedPercent = 87.5,
      double targetVmgKnots = -4.6,
      List<String> criticalWarnings = const ['Műszer-kapcsolat megszakadt'],
    }) {
      return WatchPayload(
        timestamp: timestamp ?? buildTime,
        gpsTimeUtc: gpsTimeUtc ?? gpsTime,
        isGpsTimeTrusted: isGpsTimeTrusted,
        sogKnots: sogKnots,
        currentTwa: currentTwa,
        predictedTwaAtMark: predictedTwaAtMark,
        forecastBandDegrees: forecastBandDegrees,
        courseCorrection: courseCorrection,
        etaSeconds: etaSeconds,
        distanceMeters: distanceMeters,
        markName: markName,
        targetSpeedPercent: targetSpeedPercent,
        targetVmgKnots: targetVmgKnots,
        criticalWarnings: criticalWarnings,
      );
    }

    group('JSON round-trip', () {
      test('preserves all displayed values through round-trip', () {
        // Arrange
        final original = sample();

        // Act
        final restored = WatchPayload.fromJson(original.toJson());

        // Assert — a props-fedett mezők egyenlősége + a v1-null vmg
        expect(restored, equals(original));
        expect(restored.vmgKnots, isNull);
        expect(restored.targetVmgKnots, equals(-4.6));
      });

      test('preserves timestamp and gpsTimeUtc excluded from equality', () {
        // A timestamp és a gpsTimeUtc nincs a props-ban, ezért külön
        // ellenőrizzük, hogy a szerializáció átviszi őket.
        // Arrange
        final original = sample();

        // Act
        final restored = WatchPayload.fromJson(original.toJson());

        // Assert
        expect(restored.timestamp, equals(buildTime));
        expect(restored.gpsTimeUtc, equals(gpsTime));
      });

      test('round-trips an all-null payload with explicit null fields', () {
        // Arrange
        final original = WatchPayload(timestamp: buildTime);

        // Act
        final json = original.toJson();
        final restored = WatchPayload.fromJson(json);

        // Assert — az opcionális mezők explicit null-ként mennek és jönnek vissza
        expect(json.containsKey('sogKnots'), isTrue);
        expect(json['sogKnots'], isNull);
        expect(restored.gpsTimeUtc, isNull);
        expect(restored.sogKnots, isNull);
        expect(restored.markName, isNull);
        expect(restored.isGpsTimeTrusted, isFalse);
        expect(restored.criticalWarnings, isEmpty);
      });

      test('serializes DateTime as epoch millis and reconstructs as UTC', () {
        // Egy lokális forrás-DateTime is UTC-instantként kell visszajöjjön.
        // Arrange
        final localSource = DateTime.fromMillisecondsSinceEpoch(
          gpsTime.millisecondsSinceEpoch,
        );
        expect(localSource.isUtc, isFalse);
        final payload = WatchPayload(
          timestamp: buildTime,
          gpsTimeUtc: localSource,
        );

        // Act
        final restored = WatchPayload.fromJson(payload.toJson());

        // Assert
        expect(restored.gpsTimeUtc!.isUtc, isTrue);
        expect(
          restored.gpsTimeUtc!.millisecondsSinceEpoch,
          equals(gpsTime.millisecondsSinceEpoch),
        );
      });

      test('preserves a non-empty localized critical warnings list', () {
        // Arrange
        const warnings = ['Műszer-kapcsolat megszakadt', 'GPS-jel elveszett'];
        final payload = WatchPayload(
          timestamp: buildTime,
          criticalWarnings: warnings,
        );

        // Act
        final restored = WatchPayload.fromJson(payload.toJson());

        // Assert
        expect(restored.criticalWarnings, equals(warnings));
      });
    });

    group('defensive decoding', () {
      test('reads whole-number JSON values as double', () {
        // A natív híd átszerializálhatja a JSON-t; egy egész (pl. 5) is double
        // mezőként kell dekódoljon.
        // Arrange
        final json = <String, dynamic>{
          'timestamp': buildTime.millisecondsSinceEpoch,
          'sogKnots': 5,
          'distanceMeters': 480,
        };

        // Act
        final restored = WatchPayload.fromJson(json);

        // Assert
        expect(restored.sogKnots, equals(5.0));
        expect(restored.distanceMeters, equals(480.0));
      });

      test('defaults missing isGpsTimeTrusted and criticalWarnings', () {
        // Arrange
        final json = <String, dynamic>{
          'timestamp': buildTime.millisecondsSinceEpoch,
        };

        // Act
        final restored = WatchPayload.fromJson(json);

        // Assert
        expect(restored.isGpsTimeTrusted, isFalse);
        expect(restored.criticalWarnings, isEmpty);
      });
    });

    group('value equality (change-detect alapja)', () {
      test('ignores timestamp differences', () {
        // A 500 ms-os change-detect nem indulhat csak a build-idő miatt.
        // Arrange / Act
        final a = sample();
        final laterBuild = sample(
          timestamp: buildTime.add(const Duration(seconds: 1)),
        );

        // Assert
        expect(a, equals(laterBuild));
        expect(a.hashCode, equals(laterBuild.hashCode));
      });

      test(
        'ignores gpsTimeUtc differences so the clock tick does not retrigger',
        () {
          // Arrange / Act
          final base = sample();
          final tick = sample(
            gpsTimeUtc: gpsTime.add(const Duration(seconds: 1)),
          );

          // Assert
          expect(base, equals(tick));
        },
      );

      test('differs when a displayed value changes', () {
        // Arrange / Act
        final base = sample();
        final faster = sample(sogKnots: 7.1);

        // Assert
        expect(base, isNot(equals(faster)));
      });

      test('differs when critical warnings change', () {
        // Arrange / Act
        final base = sample();
        final withExtra = sample(
          criticalWarnings: const [
            'Műszer-kapcsolat megszakadt',
            'GPS-jel elveszett',
          ],
        );

        // Assert
        expect(base, isNot(equals(withExtra)));
      });

      test('differs when forecastBandDegrees changes', () {
        final base = sample();
        final wider = sample(forecastBandDegrees: 11);
        expect(base, isNot(equals(wider)));
      });

      test('differs when targetSpeedPercent changes', () {
        final base = sample();
        final slower = sample(targetSpeedPercent: 72);
        expect(base, isNot(equals(slower)));
      });
      test('differs when targetVmgKnots changes', () {
        final base = sample();
        final offTarget = sample(targetVmgKnots: -3.2);
        expect(base, isNot(equals(offTarget)));
      });
    });
  });
}
