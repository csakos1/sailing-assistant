import 'dart:async';

import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/app/true_time.dart';
import 'package:phone/providers/active_race_provider.dart';
import 'package:phone/providers/active_warnings_provider.dart';
import 'package:phone/providers/boat_state_provider.dart';
import 'package:phone/providers/connection_status_provider.dart';
import 'package:phone/providers/polar_provider.dart';
import 'package:phone/providers/tick_provider.dart';
import 'package:phone/providers/true_time_provider.dart';
import 'package:phone/providers/wind_shift_trend_provider.dart';
import 'package:shared/shared.dart';

void main() {
  final tickTime = DateTime.utc(2025, 6, 1, 10, 0, 30);
  final anchorUtc = DateTime.utc(2025, 6, 1, 10);
  const position = Coordinate(latitude: 46.9, longitude: 17.9);
  final samplePolar = Polar(
    twaAxis: const [0, 90, 180],
    twsAxis: const [6, 12],
    grid: const [
      [null, null],
      [4, 6],
      [3, 5],
    ],
  );

  final gnssReading = TrueTimeReading(
    utc: anchorUtc,
    source: TrueTimeSource.gnss,
  );
  final unsyncedReading = TrueTimeReading(
    utc: anchorUtc,
    source: TrueTimeSource.wallClockUnsynced,
  );

  BoatState boat({DateTime? instrumentTimeUtc, bool hasFix = true}) =>
      BoatState(
        lastUpdate: anchorUtc,
        position: hasFix ? position : null,
        instrumentTimeUtc: instrumentTimeUtc,
      );

  final sampleTrend = WindShiftTrend(
    shiftRateDegPerMinute: 2,
    currentTwd: const Bearing.true_(200),
    confidence: WindShiftConfidence.high,
    sampleCount: 15,
    windowDuration: const Duration(minutes: 10),
    residualStdErrorDeg: 1.2,
    slopeStdErrorDegPerMin: 0.3,
    meanSampleTime: anchorUtc,
  );

  late StreamController<DateTime> ticks;

  ProviderContainer makeContainer({
    ConnectionStatus status = const Connected(),
    BoatState? boatState,
    WindShiftTrend? trend,
    Race? race,
    TrueTimeReading? trueTime,
    bool polarMissing = false,
  }) {
    ticks = StreamController<DateTime>.broadcast();
    final container = ProviderContainer(
      overrides: [
        tickProvider.overrideWith((ref) => ticks.stream),
        connectionStatusProvider.overrideWith(
          () => _FixedConnectionStatus(status),
        ),
        boatStateProvider.overrideWith(
          () => _FixedBoatState(boatState ?? boat()),
        ),
        windShiftTrendProvider.overrideWithValue(trend),
        activeRaceProvider.overrideWith(() => _FixedActiveRace(race)),
        trueTimeProvider.overrideWithValue(() => trueTime ?? gnssReading),
        polarProvider.overrideWith(
          (ref) async => polarMissing
              ? const Err<Polar, PolarLoadError>(PolarAssetMissing())
              : Ok<Polar, PolarLoadError>(samplePolar),
        ),
      ],
    )..listen(activeWarningsProvider, (_, _) {});
    addTearDown(ticks.close);
    addTearDown(container.dispose);
    return container;
  }

  Future<void> tick() async {
    ticks.add(tickTime);
    await pumpEventQueue();
  }

  // Aktív race (status == active) a WindShiftTrendInsufficient gatinghez.
  Race activeRace() => Race.create(
    id: 'r1',
    name: 'V',
    marks: const [Mark(sequence: 1, name: 'Z1', position: position)],
  ).start(at: anchorUtc);

  group('activeWarningsProvider', () {
    test('első tick előtt → üres lista', () {
      final container = makeContainer();
      expect(container.read(activeWarningsProvider), isEmpty);
    });

    test('csatlakozott, minden rendben → üres lista', () async {
      final container = makeContainer(trend: sampleTrend, race: activeRace());
      await tick();
      expect(container.read(activeWarningsProvider), isEmpty);
    });

    test('polár-betöltés Err → PolarMissing (info)', () async {
      final container = makeContainer(
        trend: sampleTrend,
        race: activeRace(),
        polarMissing: true,
      );
      await tick();
      expect(
        container.read(activeWarningsProvider),
        contains(const PolarMissing()),
      );
    });

    test('nem csatlakozott → csak GatewayDisconnected (suppression)', () async {
      final container = makeContainer(
        status: const Disconnected(),
        boatState: boat(hasFix: false),
        race: activeRace(),
        trueTime: unsyncedReading,
      );
      await tick();
      expect(container.read(activeWarningsProvider), [
        const GatewayDisconnected(),
      ]);
    });

    test('wallClockUnsynced → GpsTimeUnsynced (isTimeUnsynced map)', () async {
      final container = makeContainer(trueTime: unsyncedReading);
      await tick();
      expect(
        container.read(activeWarningsProvider),
        contains(const GpsTimeUnsynced()),
      );
    });

    test('drift a küszöb fölött → GpsTimeUnsynced (drift map)', () async {
      // trueTime.utc − instrument = +15 mp (> 10 mp).
      final container = makeContainer(
        boatState: boat(
          instrumentTimeUtc: anchorUtc.subtract(const Duration(seconds: 15)),
        ),
      );
      await tick();
      expect(
        container.read(activeWarningsProvider),
        contains(const GpsTimeUnsynced()),
      );
    });

    test('drift a normál Vulcan-késés tartományában (4 mp) → nincs', () async {
      final container = makeContainer(
        boatState: boat(
          instrumentTimeUtc: anchorUtc.subtract(const Duration(seconds: 4)),
        ),
      );
      await tick();
      expect(
        container.read(activeWarningsProvider),
        isNot(contains(const GpsTimeUnsynced())),
      );
    });

    test('hiányzó instrumentTimeUtc → drift null → nincs jelzés', () async {
      final container = makeContainer(boatState: boat());
      await tick();
      expect(
        container.read(activeWarningsProvider),
        isNot(contains(const GpsTimeUnsynced())),
      );
    });

    test('trend null + aktív race → WindShiftTrendInsufficient', () async {
      final container = makeContainer(race: activeRace());
      await tick();
      expect(
        container.read(activeWarningsProvider),
        contains(const WindShiftTrendInsufficient()),
      );
    });

    test('trend null + nincs race → notStarted → nincs insufficient', () async {
      // A default race null → raceStatus notStarted (a makeContainer-ben).
      final container = makeContainer();
      await tick();
      expect(
        container.read(activeWarningsProvider),
        isNot(contains(const WindShiftTrendInsufficient())),
      );
    });

    test('trend jelen + aktív race → nincs insufficient', () async {
      final container = makeContainer(trend: sampleTrend, race: activeRace());
      await tick();
      expect(
        container.read(activeWarningsProvider),
        isNot(contains(const WindShiftTrendInsufficient())),
      );
    });

    test('halmozódás: a fix prioritási sorrend megőrződik', () async {
      // Nincs pozíció + wallClockUnsynced + trend null & aktív race.
      final container = makeContainer(
        boatState: boat(hasFix: false),
        race: activeRace(),
        trueTime: unsyncedReading,
      );
      await tick();
      expect(container.read(activeWarningsProvider), const [
        GpsSignalLost(),
        GpsTimeUnsynced(),
        WindShiftTrendInsufficient(),
      ]);
    });
  });
}

class _FixedConnectionStatus extends ConnectionStatusNotifier {
  _FixedConnectionStatus(this._status);

  final ConnectionStatus _status;

  @override
  ConnectionStatus build() => _status;
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
