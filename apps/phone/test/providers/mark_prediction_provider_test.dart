import 'dart:async';

import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/providers/active_race_provider.dart';
import 'package:phone/providers/boat_state_provider.dart';
import 'package:phone/providers/mark_prediction_provider.dart';
import 'package:phone/providers/tick_provider.dart';
import 'package:phone/providers/wind_shift_trend_provider.dart';

void main() {
  final tickTime = DateTime.utc(2026, 5, 28, 10, 30);
  final startTime = DateTime.utc(2026, 5, 28, 10);

  const boatPosition = Coordinate(latitude: 46.90, longitude: 18.05);
  const markA = Mark(
    sequence: 1,
    name: 'Z1',
    position: Coordinate(latitude: 46.92, longitude: 18.08),
  );
  const markB = Mark(
    sequence: 2,
    name: 'Z2',
    position: Coordinate(latitude: 46.95, longitude: 18.12),
  );

  final boatWithPosition = BoatState(
    lastUpdate: tickTime,
    position: boatPosition,
    courseOverGround: const Bearing.true_(45),
    speedOverGround: const Speed(metersPerSecond: 4),
  );
  final boatWithoutPosition = BoatState(lastUpdate: tickTime);

  late StreamController<DateTime> ticks;

  ProviderContainer makeContainer({
    required BoatState boatState,
    required Race? race,
    WindShiftTrend? trend,
  }) {
    ticks = StreamController<DateTime>.broadcast();
    final container = ProviderContainer(
      overrides: [
        tickProvider.overrideWith((ref) => ticks.stream),
        boatStateProvider.overrideWith(() => _FixedBoatState(boatState)),
        activeRaceProvider.overrideWith(() => _FixedActiveRace(race)),
        windShiftTrendProvider.overrideWithValue(trend),
      ],
    )..listen(markPredictionProvider, (_, _) {});
    addTearDown(ticks.close);
    addTearDown(container.dispose);
    return container;
  }

  Future<void> tick() async {
    ticks.add(tickTime);
    await pumpEventQueue();
  }

  Race activeRace(List<Mark> marks) =>
      Race.create(id: 'r1', name: 'V', marks: marks).start(at: startTime);

  group('markPredictionProvider', () {
    test('első tick előtt → null', () {
      final container = makeContainer(
        boatState: boatWithPosition,
        race: activeRace(const [markA, markB]),
      );
      expect(container.read(markPredictionProvider), isNull);
    });

    test('nincs aktív race → null', () async {
      final container = makeContainer(boatState: boatWithPosition, race: null);
      await tick();
      expect(container.read(markPredictionProvider), isNull);
    });

    test('nincs pozíció → null', () async {
      final container = makeContainer(
        boatState: boatWithoutPosition,
        race: activeRace(const [markA, markB]),
      );
      await tick();
      expect(container.read(markPredictionProvider), isNull);
    });

    test('finished race (nincs aktív bóya) → null', () async {
      final finished = Race.create(
        id: 'r1',
        name: 'V',
        marks: const [markA],
      ).start(at: startTime).roundCurrentMark(at: tickTime);
      final container = makeContainer(
        boatState: boatWithPosition,
        race: finished,
      );
      await tick();
      expect(container.read(markPredictionProvider), isNull);
    });

    test(
      'aktív bóya + pozíció → prediction, mark és calculatedAt bekötve',
      () async {
        final container = makeContainer(
          boatState: boatWithPosition,
          race: activeRace(const [markA, markB]),
        );
        await tick();

        final prediction = container.read(markPredictionProvider);
        expect(prediction, isNotNull);
        expect(prediction!.mark, markA);
        // A now a tickből csorog le.
        expect(prediction.calculatedAt, equals(tickTime));
        // Trend nélkül a konfidencia low.
        expect(prediction.shiftConfidence, WindShiftConfidence.low);
      },
    );
  });
}

class _FixedBoatState extends BoatStateNotifier {
  _FixedBoatState(this._state);

  final BoatState _state;

  @override
  BoatState build() => _state;
}

class _FixedActiveRace extends ActiveRaceNotifier {
  _FixedActiveRace(this._race);

  final Race? _race;

  @override
  Race? build() => _race;
}
