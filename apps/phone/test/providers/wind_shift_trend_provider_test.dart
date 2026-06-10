import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/providers/race_snapshot_provider.dart';
import 'package:phone/providers/wind_shift_trend_provider.dart';

void main() {
  final clock = DateTime.utc(2026, 5, 28, 10);

  RaceSnapshot snapshotWith({WindShiftTrend? trend}) => RaceSnapshot(
    eventCount: 1,
    boatState: BoatState(lastUpdate: clock),
    connectionStatus: const Connected(),
    tickTime: clock,
    windShiftTrend: trend,
  );

  ProviderContainer makeContainer(RaceSnapshot? snapshot) {
    final container = ProviderContainer(
      overrides: [
        raceSnapshotProvider.overrideWith(() => _FixedSnapshot(snapshot)),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('windShiftTrendProvider', () {
    test('nincs snapshot → null', () {
      expect(makeContainer(null).read(windShiftTrendProvider), isNull);
    });

    test('snapshot trend nélkül → null', () {
      expect(
        makeContainer(snapshotWith()).read(windShiftTrendProvider),
        isNull,
      );
    });

    test('snapshot trenddel → a hordozott WindShiftTrend', () {
      final trend = WindShiftTrend(
        shiftRateDegPerMinute: 2,
        currentTwd: const Bearing.true_(200),
        confidence: WindShiftConfidence.high,
        sampleCount: 15,
        windowDuration: const Duration(minutes: 10),
        residualStdErrorDeg: 1.2,
        slopeStdErrorDegPerMin: 0.3,
        meanSampleTime: clock,
      );
      expect(
        makeContainer(snapshotWith(trend: trend)).read(windShiftTrendProvider),
        equals(trend),
      );
    });
  });
}

class _FixedSnapshot extends RaceSnapshotNotifier {
  _FixedSnapshot(this._snapshot);

  final RaceSnapshot? _snapshot;

  @override
  RaceSnapshot? build() => _snapshot;
}
