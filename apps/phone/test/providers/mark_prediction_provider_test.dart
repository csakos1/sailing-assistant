import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/providers/mark_prediction_provider.dart';
import 'package:phone/providers/race_snapshot_provider.dart';

void main() {
  final clock = DateTime.utc(2026, 5, 28, 10);

  const mark = Mark(
    sequence: 1,
    name: 'Z1',
    position: Coordinate(latitude: 46.92, longitude: 18.08),
  );

  RaceSnapshot snapshotWith({MarkPrediction? prediction}) => RaceSnapshot(
    eventCount: 1,
    boatState: BoatState(lastUpdate: clock),
    connectionStatus: const Connected(),
    tickTime: clock,
    prediction: prediction,
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

  group('markPredictionProvider', () {
    test('nincs snapshot → null', () {
      expect(makeContainer(null).read(markPredictionProvider), isNull);
    });

    test('snapshot prediction nélkül → null', () {
      expect(
        makeContainer(snapshotWith()).read(markPredictionProvider),
        isNull,
      );
    });

    test('snapshot prediction-nel → a hordozott MarkPrediction', () {
      final prediction = MarkPrediction(
        mark: mark,
        bearingToMark: const Bearing.true_(110),
        distanceToMark: const Distance(meters: 850),
        etaSource: EtaSource.sog,
        shiftConfidence: WindShiftConfidence.medium,
        calculatedAt: clock,
        eta: const Duration(minutes: 4, seconds: 25),
        predictedTwaAtMark: const Angle(degrees: -38),
      );
      expect(
        makeContainer(
          snapshotWith(prediction: prediction),
        ).read(markPredictionProvider),
        equals(prediction),
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
