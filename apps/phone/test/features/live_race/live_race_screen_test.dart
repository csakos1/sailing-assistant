import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/app/localization_delegates.dart';
import 'package:phone/app/screen_wake_lock.dart';
import 'package:phone/app/true_time.dart';
import 'package:phone/features/live_race/instruments_race_chooser_provider.dart';
import 'package:phone/features/live_race/live_race_screen.dart';
import 'package:phone/features/live_race/today_races_provider.dart';
import 'package:phone/features/live_race/widgets/data_rail.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:phone/providers/active_race_provider.dart';
import 'package:phone/providers/active_warnings_provider.dart';
import 'package:phone/providers/clock_provider.dart';
import 'package:phone/providers/engine_service_error_provider.dart';
import 'package:phone/providers/engine_session_provider.dart';
import 'package:phone/providers/engine_session_state.dart';
import 'package:phone/providers/gps_time_reading_provider.dart';
import 'package:phone/providers/instruments_race_chooser.dart';
import 'package:phone/providers/local_wall_clock_provider.dart';
import 'package:phone/providers/mark_prediction_provider.dart';
import 'package:phone/providers/race_engine_host_provider.dart';
import 'package:phone/providers/race_list_provider.dart';
import 'package:phone/providers/race_repository_provider.dart';
import 'package:phone/providers/race_snapshot_provider.dart';
import 'package:phone/providers/screen_wake_lock_provider.dart';
import 'package:phone/providers/tick_provider.dart';
import 'package:phone/providers/wind_data_provider.dart';

import '../../providers/in_memory_repositories.dart';
import '../../providers/recording_engine_host.dart';

class _FixedActiveRace extends ActiveRaceNotifier {
  _FixedActiveRace(this._race);
  final Race? _race;
  @override
  Race? build() => _race;
}

class _FixedSession extends EngineSessionNotifier {
  _FixedSession(this._initial);
  final EngineSessionState _initial;
  @override
  EngineSessionState build() => _initial;
}

class _FixedSnapshot extends RaceSnapshotNotifier {
  _FixedSnapshot(this._snapshot);
  final RaceSnapshot? _snapshot;
  @override
  RaceSnapshot? build() => _snapshot;

  // A teszt egy uj pillanatkepet ad (pl. a cel utan).
  // ignore: use_setters_to_change_properties
  void emit(RaceSnapshot? snapshot) => state = snapshot;
}

class _FixedWindData extends WindDataNotifier {
  _FixedWindData(this._wind);
  final WindData? _wind;
  @override
  WindData? build() => _wind;
}

class _RoundMarkHost extends RecordingEngineHost {
  int roundMarkCount = 0;

  @override
  void sendRoundMarkCommand() => roundMarkCount++;
}

class _SpyScreenWakeLock implements ScreenWakeLock {
  int enableCount = 0;
  int disableCount = 0;

  @override
  Future<void> enable() async {
    enableCount++;
  }

  @override
  Future<void> disable() async {
    disableCount++;
  }
}

const _running = EngineRunning(cause: EngineStartCause.gatewayFound);

final _now = DateTime(2026, 5, 29, 14, 32, 10);

const _m1 = Mark(
  sequence: 1,
  name: '1. bója',
  position: Coordinate(latitude: 47, longitude: 18),
);

const _m2 = Mark(
  sequence: 2,
  name: '2. bója',
  position: Coordinate(latitude: 48, longitude: 19),
);

const _startPoint = StartPoint(
  name: 'Rajtvonal',
  position: Coordinate(latitude: 46.9, longitude: 17.9),
);

Race _race({String id = 'r1', String name = 'Teszt verseny'}) =>
    Race.create(id: id, name: name, marks: const [_m1, _m2]).copyWith(
      scheduledStartAt: DateTime.utc(2026, 5, 29, 16),
      startPoint: _startPoint,
    );

Race _activeRace() => _race().start(at: DateTime(2026, 5, 29, 14));

MarkPrediction _prediction({Mark mark = _m1}) => MarkPrediction(
  mark: mark,
  bearingToMark: const Bearing.true_(95),
  courseCorrection: const Angle(degrees: 8),
  distanceToMark: const Distance(meters: 450),
  eta: const Duration(minutes: 7, seconds: 32),
  etaSource: EtaSource.sog,
  predictedTwaAtMark: const Angle(degrees: -47),
  shiftConfidence: WindShiftConfidence.medium,
  calculatedAt: _now,
);

WindData _wind() => WindData(
  apparentAngle: const Angle(degrees: 30),
  apparentSpeed: const Speed(metersPerSecond: 5),
  timestamp: _now,
  trueAngleWater: const Angle(degrees: 32),
);

// 3,3 m/s = 6,4 kn.
RaceSnapshot _snapshot({
  required String? raceId,
  required RaceStatus? raceStatus,
  ConnectionStatus status = const Connected(),
  DateTime? lastUpdate,
  Speed? stw = const Speed(metersPerSecond: 3.3),
}) => RaceSnapshot(
  eventCount: 120,
  boatState: BoatState(
    lastUpdate: lastUpdate ?? _now,
    speedThroughWater: stw,
  ),
  connectionStatus: status,
  tickTime: _now,
  raceId: raceId,
  raceStatus: raceStatus,
  targetSpeedKnots: 6.8,
  vmgKnots: 5.8,
  targetVmgKnots: 6.2,
);

double _gridOpacity(WidgetTester tester) => tester
    .widget<Opacity>(
      find
          .ancestor(of: find.byType(DataRail), matching: find.byType(Opacity))
          .first,
    )
    .opacity;

ProviderContainer _container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(LiveRaceScreen)));

Future<void> _pump(
  WidgetTester tester, {
  required Race? selected,
  required RaceSnapshot? snapshot,
  EngineSessionState session = _running,
  List<Race> races = const [],
  List<Race> todayRaces = const [],
  MarkPrediction? prediction,
  WindData? wind,
  List<Warning> warnings = const [],
  String? serviceError,
  TrueTimeReading? trueTime,
  ScreenWakeLock? wakeLock,
  RecordingEngineHost? host,
  InMemoryRaceRepository? repository,
  InstrumentsRaceChooser? chooser,
}) async {
  tester.view.physicalSize = const Size(412, 892);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final reading =
      trueTime ??
      TrueTimeReading(
        utc: DateTime(2026, 5, 29, 14, 32, 7),
        source: TrueTimeSource.gnss,
      );
  final engineHost = host ?? RecordingEngineHost();
  addTearDown(engineHost.close);
  final raceRepository = repository ?? InMemoryRaceRepository();
  addTearDown(raceRepository.close);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        activeRaceProvider.overrideWith(() => _FixedActiveRace(selected)),
        engineSessionProvider.overrideWith(() => _FixedSession(session)),
        raceSnapshotProvider.overrideWith(() => _FixedSnapshot(snapshot)),
        raceListProvider.overrideWith((ref) => Stream.value(races)),
        todayRacesProvider.overrideWithValue(todayRaces),
        markPredictionProvider.overrideWithValue(prediction),
        windDataProvider.overrideWith(() => _FixedWindData(wind)),
        activeWarningsProvider.overrideWithValue(warnings),
        engineServiceErrorProvider.overrideWith((ref) => serviceError),
        gpsTimeReadingProvider.overrideWith(
          (ref) => Stream<TrueTimeReading>.value(reading),
        ),
        tickProvider.overrideWith((ref) => Stream<DateTime>.value(_now)),
        screenWakeLockProvider.overrideWithValue(
          wakeLock ?? _SpyScreenWakeLock(),
        ),
        raceEngineHostProvider.overrideWithValue(engineHost),
        raceRepositoryProvider.overrideWithValue(raceRepository),
        clockProvider.overrideWithValue(() => _now),
        localWallClockProvider.overrideWithValue((instant) => instant.toUtc()),
        if (chooser != null)
          instrumentsRaceChooserProvider.overrideWithValue(chooser),
      ],
      child: MaterialApp(
        theme: foretackTheme,
        localizationsDelegates: phoneLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const LiveRaceScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpRacing(
  WidgetTester tester, {
  MarkPrediction? prediction,
  RaceSnapshot? snapshot,
  List<Warning> warnings = const [],
  String? serviceError,
  TrueTimeReading? trueTime,
  ScreenWakeLock? wakeLock,
  RecordingEngineHost? host,
}) => _pump(
  tester,
  selected: _activeRace(),
  snapshot: snapshot ?? _snapshot(raceId: 'r1', raceStatus: RaceStatus.active),
  prediction: prediction ?? _prediction(),
  wind: _wind(),
  warnings: warnings,
  serviceError: serviceError,
  trueTime: trueTime,
  wakeLock: wakeLock,
  host: host,
);

void main() {
  group('racing (34c)', () {
    testWidgets('shows the race, the target mark and the speed cell', (
      tester,
    ) async {
      await _pumpRacing(tester);

      expect(find.text('Teszt verseny'), findsOneWidget);
      expect(find.text('1. bója'), findsOneWidget);
      expect(find.text('14:32:07'), findsOneWidget);
      expect(find.text('47°'), findsOneWidget); // TWA kov.
      expect(find.text('8°'), findsOneWidget);
      expect(find.text('jobbra'), findsOneWidget);
      expect(find.text('32°'), findsOneWidget); // TWA most
      expect(find.text('STW'), findsOneWidget);
      expect(find.text('6,4'), findsOneWidget);
      expect(find.text('450 m'), findsOneWidget);
      expect(find.text('07:32'), findsOneWidget);
      expect(find.text('cél 6,2'), findsOneWidget);
      // A BEARING cella megszunt, helyen a sebesseg.
      expect(find.text('BEARING'), findsNothing);
      expect(find.text('095°'), findsNothing);
      expect(find.text('ELAVULT'), findsNothing);
    });

    testWidgets('shows SOG in the same cell without STW', (tester) async {
      await _pumpRacing(
        tester,
        snapshot: RaceSnapshot(
          eventCount: 120,
          boatState: BoatState(
            lastUpdate: _now,
            speedOverGround: const Speed(metersPerSecond: 3.3),
          ),
          connectionStatus: const Connected(),
          tickTime: _now,
          raceId: 'r1',
          raceStatus: RaceStatus.active,
        ),
      );

      expect(find.text('SOG'), findsOneWidget);
      expect(find.text('STW'), findsNothing);
      expect(find.text('6,4'), findsOneWidget);
    });

    testWidgets('the strip names the stepped mark of the engine', (
      tester,
    ) async {
      // Az engine mar M2-re lepett, a UI-Race meg M1-en all.
      await _pumpRacing(tester, prediction: _prediction(mark: _m2));

      expect(find.text('2. bója'), findsOneWidget);
      expect(find.text('1. bója'), findsNothing);
    });

    testWidgets('the round mark bar is full width, 56 dp, square', (
      tester,
    ) async {
      await _pumpRacing(tester);

      final bar = find.widgetWithText(FilledButton, 'Bója megvan');
      final size = tester.getSize(bar);
      expect(size.height, 56);
      expect(size.width, 412);
      final style = tester.widget<FilledButton>(bar).style;
      expect(style?.shape?.resolve(const {}), const RoundedRectangleBorder());
      expect(find.text('Rajt most'), findsNothing);
    });

    testWidgets('the round mark is sent only after the confirmation', (
      tester,
    ) async {
      final host = _RoundMarkHost();
      await _pumpRacing(tester, host: host);

      await tester.tap(find.text('Bója megvan'));
      await tester.pumpAndSettle();
      expect(find.text('Bója megkerülve?'), findsOneWidget);
      expect(host.roundMarkCount, 0);

      await tester.tap(find.text('Megvan'));
      await tester.pumpAndSettle();
      expect(host.roundMarkCount, 1);
    });

    testWidgets('degrades nav-dependent cells without a prediction', (
      tester,
    ) async {
      await _pump(
        tester,
        selected: _activeRace(),
        snapshot: _snapshot(
          raceId: 'r1',
          raceStatus: RaceStatus.active,
          stw: null,
        ),
        wind: _wind(),
      );

      // TWA most es a VMG (a pillanatkepbol) megvan; TWA kov., korrekcio,
      // sebesseg, tav, ETA, cel-% nincs. A strip a verseny aktiv bojajat
      // mutatja.
      expect(find.text('32°'), findsOneWidget);
      expect(find.text('1. bója'), findsOneWidget);
      expect(find.text('—'), findsNWidgets(6));
    });

    testWidgets('shows the stale chip when connected data is old', (
      tester,
    ) async {
      await _pumpRacing(
        tester,
        snapshot: _snapshot(
          raceId: 'r1',
          raceStatus: RaceStatus.active,
          lastUpdate: _now.subtract(const Duration(seconds: 10)),
        ),
      );

      expect(find.text('ELAVULT'), findsOneWidget);
    });

    testWidgets('a lost link shows the data age and dims the grid', (
      tester,
    ) async {
      // A futo engine kliense ujraprobalkozas kozben Connecting es
      // ConnectionError kozott valt; mindketto megszakadt.
      await _pumpRacing(
        tester,
        snapshot: _snapshot(
          raceId: 'r1',
          raceStatus: RaceStatus.active,
          status: const ConnectionError('Szakadt'),
          lastUpdate: _now.subtract(const Duration(minutes: 1, seconds: 12)),
        ),
      );

      expect(find.text('ADAT'), findsOneWidget);
      expect(find.text('1:12 perce'), findsOneWidget);
      expect(_gridOpacity(tester), 0.42);
    });

    testWidgets('a gateway warning keeps the critical banner on a race', (
      tester,
    ) async {
      await _pumpRacing(tester, warnings: const [GatewayDisconnected()]);

      expect(find.text('Nincs kapcsolat a műszerekkel'), findsOneWidget);
      expect(_gridOpacity(tester), 0.4);
    });

    testWidgets('an info warning shows a banner, the grid stays', (
      tester,
    ) async {
      await _pumpRacing(
        tester,
        warnings: const [WindShiftTrendInsufficient()],
      );

      expect(find.text('Kevés széladat a trendhez'), findsOneWidget);
      expect(_gridOpacity(tester), 1.0);
    });

    testWidgets('a service error shows the error row', (tester) async {
      await _pumpRacing(tester, serviceError: 'boom');

      expect(find.text('Háttér-engine hiba: boom'), findsOneWidget);
    });

    testWidgets('marks an unsynced GPS time with a tilde', (tester) async {
      await _pumpRacing(
        tester,
        trueTime: TrueTimeReading(
          utc: DateTime(2026, 5, 29, 14, 32, 7),
          source: TrueTimeSource.wallClockUnsynced,
        ),
      );

      expect(find.text('~14:32:07'), findsOneWidget);
    });

    testWidgets('the stop in the menu asks to stop the race', (tester) async {
      await _pumpRacing(tester);

      await tester.tap(find.byTooltip('Menü'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Leállítás'));
      await tester.pumpAndSettle();

      expect(find.text('Verseny leállítása'), findsOneWidget);
    });

    testWidgets('keeps the screen on and releases it on dispose', (
      tester,
    ) async {
      final spy = _SpyScreenWakeLock();
      await _pumpRacing(tester, wakeLock: spy);
      expect(spy.enableCount, 1);
      expect(spy.disableCount, 0);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();

      expect(spy.disableCount, 1);
    });
  });

  group('pre-start (34b)', () {
    Future<void> pumpPreStart(
      WidgetTester tester, {
      List<Race> todayRaces = const [],
      RecordingEngineHost? host,
      InMemoryRaceRepository? repository,
      InstrumentsRaceChooser? chooser,
      ScreenWakeLock? wakeLock,
    }) => _pump(
      tester,
      selected: null,
      snapshot: _snapshot(raceId: 'r1', raceStatus: RaceStatus.notStarted),
      races: [_race()],
      todayRaces: todayRaces,
      prediction: _prediction(
        mark: _startPoint.asGuidanceMark(),
      ),
      wind: _wind(),
      host: host,
      repository: repository,
      chooser: chooser,
      wakeLock: wakeLock,
    );

    testWidgets('shows the race name and the start-now bar only', (
      tester,
    ) async {
      await pumpPreStart(tester);

      expect(find.text('Teszt verseny'), findsOneWidget);
      // A csikban nincs cel-boja es nincs rajtido (34b).
      expect(find.byIcon(Icons.chevron_right), findsNothing);
      expect(find.text('Rajt most'), findsOneWidget);
      expect(find.text('Bója megvan'), findsNothing);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      // Egy mai verseny: nincs valto.
      expect(find.byIcon(Icons.expand_more), findsNothing);
    });

    testWidgets('keeps the screen on', (tester) async {
      final spy = _SpyScreenWakeLock();
      await pumpPreStart(tester, wakeLock: spy);

      expect(spy.enableCount, 1);
    });

    testWidgets('start now asks first, then starts the race', (tester) async {
      final repository = InMemoryRaceRepository();
      await pumpPreStart(tester, repository: repository);

      await tester.tap(find.text('Rajt most'));
      await tester.pumpAndSettle();
      expect(find.text('Rajt most?'), findsOneWidget);
      expect(repository.saved, isEmpty);

      await tester.tap(find.text('Rajt'));
      await tester.pumpAndSettle();

      final selected = _container(tester).read(activeRaceProvider);
      expect(selected?.id, 'r1');
      expect(selected?.status, RaceStatus.active);
      expect(repository.saved.single.startedAt, _now);
    });

    testWidgets('an engine start during the dialog wins over start now', (
      tester,
    ) async {
      final repository = InMemoryRaceRepository();
      await pumpPreStart(tester, repository: repository);
      await tester.tap(find.text('Rajt most'));
      await tester.pumpAndSettle();

      // Act: the engine starts the race at its scheduled time, then the
      // dialog is confirmed.
      (_container(tester).read(raceSnapshotProvider.notifier) as _FixedSnapshot)
          .emit(_snapshot(raceId: 'r1', raceStatus: RaceStatus.active));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rajt'));
      await tester.pumpAndSettle();

      // Assert: the scheduled start is kept, nothing is saved by hand.
      expect(repository.saved, isEmpty);
      expect(find.text('Bója megvan'), findsOneWidget);
    });

    testWidgets('the screen stays on when the switcher changes the race', (
      tester,
    ) async {
      final spy = _SpyScreenWakeLock();
      await _pump(
        tester,
        selected: null,
        snapshot: _snapshot(raceId: 'r1', raceStatus: RaceStatus.notStarted),
        races: [
          _race(),
          _race(id: 'r2', name: 'Esti futam'),
        ],
        wind: _wind(),
        wakeLock: spy,
      );

      // Act: the engine now leads to the other race (a new view key).
      (_container(tester).read(raceSnapshotProvider.notifier) as _FixedSnapshot)
          .emit(_snapshot(raceId: 'r2', raceStatus: RaceStatus.notStarted));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Esti futam'), findsOneWidget);
      expect(spy.enableCount, 1);
      expect(spy.disableCount, 0);
    });

    testWidgets('a cancelled start leaves the race as it is', (tester) async {
      final repository = InMemoryRaceRepository();
      await pumpPreStart(tester, repository: repository);

      await tester.tap(find.text('Rajt most'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mégse'));
      await tester.pumpAndSettle();

      expect(repository.saved, isEmpty);
      expect(_container(tester).read(activeRaceProvider), isNull);
    });

    testWidgets('the stop in the menu stops the instruments', (tester) async {
      await pumpPreStart(tester);

      await tester.tap(find.byTooltip('Menü'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Leállítás'));
      await tester.pumpAndSettle();

      expect(find.text('Műszerek leállítása'), findsOneWidget);
    });

    testWidgets('the switcher lists today and stores the choice', (
      tester,
    ) async {
      final chosen = <String>[];
      final evening = _race(id: 'r2', name: 'Esti futam');
      await pumpPreStart(
        tester,
        todayRaces: [_race(), evening],
        chooser: InstrumentsRaceChooser(
          write: (choice) async => chosen.add(choice.raceId),
          now: () => _now,
          toLocal: (instant) => instant,
          onChosen: () {},
        ),
      );

      await tester.tap(find.text('Teszt verseny'));
      await tester.pumpAndSettle();
      expect(find.text('MAI VERSENYEK'), findsOneWidget);
      expect(find.text('Esti futam'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);

      await tester.tap(find.text('Esti futam'));
      await tester.pumpAndSettle();

      expect(chosen, ['r2']);
      expect(find.text('MAI VERSENYEK'), findsNothing);
    });

    testWidgets('the scrim closes the switcher without a choice', (
      tester,
    ) async {
      final chosen = <String>[];
      await pumpPreStart(
        tester,
        todayRaces: [
          _race(),
          _race(id: 'r2', name: 'Esti futam'),
        ],
        chooser: InstrumentsRaceChooser(
          write: (choice) async => chosen.add(choice.raceId),
          now: () => _now,
          toLocal: (instant) => instant,
          onChosen: () {},
        ),
      );

      await tester.tap(find.text('Teszt verseny'));
      await tester.pumpAndSettle();
      // A lista alatti scrim: a kepernyo also resze.
      await tester.tapAt(const Offset(200, 760));
      await tester.pumpAndSettle();

      expect(find.text('MAI VERSENYEK'), findsNothing);
      expect(chosen, isEmpty);
    });
  });

  group('free mode (34a)', () {
    testWidgets('a stopped engine shows the free mode', (tester) async {
      final spy = _SpyScreenWakeLock();
      await _pump(
        tester,
        selected: _activeRace(),
        snapshot: null,
        session: const EngineStopped(),
        wakeLock: spy,
      );

      expect(find.text('Leállítva'), findsOneWidget);
      expect(find.text('Bója megvan'), findsNothing);
      // Szabad modban a kijelzo a rendszer szerint alszik el (U4).
      expect(spy.enableCount, 0);
    });

    testWidgets('the finish frees the engine and releases the screen', (
      tester,
    ) async {
      final spy = _SpyScreenWakeLock();
      await _pumpRacing(tester, wakeLock: spy);

      (_container(tester).read(raceSnapshotProvider.notifier) as _FixedSnapshot)
          .emit(_snapshot(raceId: null, raceStatus: null));
      await tester.pumpAndSettle();

      expect(find.text('Csatlakozva'), findsOneWidget);
      expect(spy.disableCount, 1);
    });
  });
}
