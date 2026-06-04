import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/providers/race_snapshot_provider.dart';
import 'package:phone/providers/wind_data_provider.dart';

void main() {
  final clock = DateTime.utc(2026, 5, 28, 10);

  RaceSnapshot snapshotWith({WindData? wind}) => RaceSnapshot(
    eventCount: 1,
    boatState: BoatState(lastUpdate: clock),
    connectionStatus: const Connected(),
    tickTime: clock,
    wind: wind,
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

  group('windDataProvider', () {
    test('nincs snapshot → null', () {
      expect(makeContainer(null).read(windDataProvider), isNull);
    });

    test('snapshot szél nélkül → null', () {
      expect(makeContainer(snapshotWith()).read(windDataProvider), isNull);
    });

    test('snapshot széllel → a hordozott WindData', () {
      final wind = WindData(
        apparentAngle: const Angle(degrees: 30),
        apparentSpeed: const Speed(metersPerSecond: 4),
        timestamp: clock,
      );
      expect(
        makeContainer(snapshotWith(wind: wind)).read(windDataProvider),
        equals(wind),
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
