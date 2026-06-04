import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/app/screen_wake_lock.dart';
import 'package:phone/app/theme.dart';
import 'package:phone/app/true_time.dart';
import 'package:phone/features/live_race/live_race_screen.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:phone/providers/active_race_provider.dart';
import 'package:phone/providers/active_warnings_provider.dart';
import 'package:phone/providers/boat_state_provider.dart';
import 'package:phone/providers/connection_status_provider.dart';
import 'package:phone/providers/engine_service_error_provider.dart';
import 'package:phone/providers/mark_prediction_provider.dart';
import 'package:phone/providers/screen_wake_lock_provider.dart';
import 'package:phone/providers/tick_provider.dart';
import 'package:phone/providers/true_time_provider.dart';
import 'package:phone/providers/wind_data_provider.dart';

class _FixedActiveRace extends ActiveRaceNotifier {
  _FixedActiveRace(this._race);
  final Race? _race;
  @override
  Race? build() => _race;
}

class _FixedBoatState extends BoatStateNotifier {
  _FixedBoatState(this._boat);
  final BoatState _boat;
  @override
  BoatState build() => _boat;
}

class _FixedWindData extends WindDataNotifier {
  _FixedWindData(this._wind);
  final WindData? _wind;
  @override
  WindData? build() => _wind;
}

class _FixedConnection extends ConnectionStatusNotifier {
  _FixedConnection(this._status);
  final ConnectionStatus _status;
  @override
  ConnectionStatus build() => _status;
}

class _NoopScreenWakeLock implements ScreenWakeLock {
  const _NoopScreenWakeLock();

  @override
  Future<void> enable() async {}

  @override
  Future<void> disable() async {}
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

Mark _mark() => const Mark(
  sequence: 1,
  name: '1. bója',
  position: Coordinate(latitude: 47, longitude: 18),
);

Race _race() => Race.create(id: 'r1', name: 'Teszt verseny', marks: [_mark()]);

MarkPrediction _prediction() => MarkPrediction(
  mark: _mark(),
  bearingToMark: const Bearing.true_(95),
  courseCorrection: const Angle(degrees: 8),
  distanceToMark: const Distance(meters: 450),
  eta: const Duration(minutes: 7, seconds: 32),
  etaSource: EtaSource.sog,
  predictedTwaAtMark: const Angle(degrees: -47),
  shiftConfidence: WindShiftConfidence.medium,
  calculatedAt: DateTime(2026, 5, 29, 14, 32, 7),
);

WindData _wind() => WindData(
  apparentAngle: const Angle(degrees: 30),
  apparentSpeed: const Speed(metersPerSecond: 5),
  timestamp: DateTime(2026, 5, 29, 14, 32, 7),
  trueAngleWater: const Angle(degrees: 32),
);

// Local DateTime-ot adunk instrumentTimeUtc-nek: a toLocal() local értéken
// identitás, így a render időzóna-független.
BoatState _boat(DateTime lastUpdate) => BoatState(
  lastUpdate: lastUpdate,
  instrumentTimeUtc: DateTime(2026, 5, 29, 14, 32, 7),
);

double _liveGridOpacity(WidgetTester tester) {
  final finder = find
      .ancestor(of: find.byType(GridView), matching: find.byType(Opacity))
      .first;
  return tester.widget<Opacity>(finder).opacity;
}

Future<void> _pump(
  WidgetTester tester, {
  required Race? race,
  required MarkPrediction? prediction,
  required WindData? wind,
  required BoatState boat,
  required ConnectionStatus status,
  DateTime? tick,
  ScreenWakeLock? wakeLock,
  TrueTimeReading? trueTime,
  List<Warning> warnings = const [],
  String? serviceError,
}) async {
  tester.view.physicalSize = const Size(1000, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final reading =
      trueTime ??
      TrueTimeReading(
        utc: DateTime(2026, 5, 29, 14, 32, 7),
        source: TrueTimeSource.gnss,
      );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        activeRaceProvider.overrideWith(() => _FixedActiveRace(race)),
        boatStateProvider.overrideWith(() => _FixedBoatState(boat)),
        windDataProvider.overrideWith(() => _FixedWindData(wind)),
        connectionStatusProvider.overrideWith(() => _FixedConnection(status)),
        markPredictionProvider.overrideWithValue(prediction),
        activeWarningsProvider.overrideWithValue(warnings),
        engineServiceErrorProvider.overrideWith((ref) => serviceError),
        trueTimeProvider.overrideWithValue(() => reading),
        screenWakeLockProvider.overrideWithValue(
          wakeLock ?? const _NoopScreenWakeLock(),
        ),
        tickProvider.overrideWith(
          (ref) => tick == null
              ? const Stream<DateTime>.empty()
              : Stream<DateTime>.value(tick),
        ),
      ],
      child: MaterialApp(
        theme: foretackTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const LiveRaceScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('LiveRaceScreen', () {
    testWidgets('renders all seven values with live data', (tester) async {
      final now = DateTime(2026, 5, 29, 14, 32, 10);
      await _pump(
        tester,
        race: _race(),
        prediction: _prediction(),
        wind: _wind(),
        boat: _boat(now),
        status: const Connected(),
        tick: now,
      );

      expect(find.text('Teszt verseny'), findsOneWidget);
      expect(find.text('Csatlakozva'), findsOneWidget);
      expect(find.text('1. bója'), findsOneWidget);
      expect(find.text('14:32:07'), findsOneWidget);
      expect(find.text('32°'), findsOneWidget); // TWA most
      expect(find.text('47°'), findsOneWidget); // TWA köv.
      expect(find.text('095°'), findsOneWidget);
      expect(find.text('8°'), findsOneWidget);
      expect(find.text('450 m'), findsOneWidget);
      expect(find.text('07:32'), findsOneWidget);
      expect(find.text('Elavult'), findsNothing);
    });

    testWidgets('a státuszsor a stepped prediction-bóját mutatja, nem a '
        'UI-Race aktív bójáját', (tester) async {
      const m1 = Mark(
        sequence: 1,
        name: '1. bója',
        position: Coordinate(latitude: 47, longitude: 18),
      );
      const m2 = Mark(
        sequence: 2,
        name: '2. bója',
        position: Coordinate(latitude: 48, longitude: 19),
      );
      final now = DateTime(2026, 5, 29, 14, 32, 10);
      await _pump(
        tester,
        // A UI-Race aktív bója-indexe M1-en áll (0, senki nem lépteti).
        race: Race.create(
          id: 'r1',
          name: 'Teszt verseny',
          marks: const [m1, m2],
        ),
        // Az engine már M2-re lépett, ezért a prediction célbóya-mezője M2.
        prediction: MarkPrediction(
          mark: m2,
          bearingToMark: const Bearing.true_(95),
          courseCorrection: const Angle(degrees: 8),
          distanceToMark: const Distance(meters: 450),
          eta: const Duration(minutes: 7, seconds: 32),
          etaSource: EtaSource.sog,
          predictedTwaAtMark: const Angle(degrees: -47),
          shiftConfidence: WindShiftConfidence.medium,
          calculatedAt: now,
        ),
        wind: _wind(),
        boat: _boat(now),
        status: const Connected(),
        tick: now,
      );

      // A célbója (M2) látszik a státuszsorban, az elhagyott M1 nem.
      expect(find.text('2. bója'), findsOneWidget);
      expect(find.text('1. bója'), findsNothing);
    });

    testWidgets('shows the empty state when there is no active race', (
      tester,
    ) async {
      await _pump(
        tester,
        race: null,
        prediction: null,
        wind: null,
        boat: _boat(DateTime(2026, 5, 29, 14)),
        status: const Disconnected(),
      );

      expect(find.text('Nincs aktív verseny'), findsOneWidget);
    });

    testWidgets('degrades nav-dependent cells to placeholders without a '
        'prediction', (tester) async {
      await _pump(
        tester,
        race: _race(),
        prediction: null,
        wind: _wind(),
        boat: _boat(DateTime(2026, 5, 29, 14)),
        status: const Connected(),
      );

      // TWA most a windData-ból megvan; a prediction-függő öt cella „—".
      expect(find.text('32°'), findsOneWidget);
      expect(find.text('—'), findsNWidgets(5));
    });

    testWidgets('shows the stale chip when connected data is old', (
      tester,
    ) async {
      final now = DateTime(2026, 5, 29, 14, 32, 20);
      await _pump(
        tester,
        race: _race(),
        prediction: _prediction(),
        wind: _wind(),
        boat: _boat(now.subtract(const Duration(seconds: 10))),
        status: const Connected(),
        tick: now,
      );

      expect(find.text('Elavult'), findsOneWidget);
    });

    testWidgets('shows the error label on a connection error', (tester) async {
      await _pump(
        tester,
        race: _race(),
        prediction: _prediction(),
        wind: _wind(),
        boat: _boat(DateTime(2026, 5, 29, 14)),
        status: const ConnectionError('Szakadt'),
      );

      expect(find.text('Hiba: Szakadt'), findsOneWidget);
    });

    testWidgets('enables the wakelock when the screen mounts', (tester) async {
      final spy = _SpyScreenWakeLock();
      final now = DateTime(2026, 5, 29, 14, 32, 10);
      await _pump(
        tester,
        race: _race(),
        prediction: _prediction(),
        wind: _wind(),
        boat: _boat(now),
        status: const Connected(),
        tick: now,
        wakeLock: spy,
      );

      expect(spy.enableCount, 1);
      expect(spy.disableCount, 0);
    });

    testWidgets('releases the wakelock when the screen is disposed', (
      tester,
    ) async {
      final spy = _SpyScreenWakeLock();
      final now = DateTime(2026, 5, 29, 14, 32, 10);
      await _pump(
        tester,
        race: _race(),
        prediction: _prediction(),
        wind: _wind(),
        boat: _boat(now),
        status: const Connected(),
        tick: now,
        wakeLock: spy,
      );

      // A fát kicseréljük → a LiveRaceScreen unmountol → dispose().
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();

      expect(spy.disableCount, 1);
    });

    testWidgets('marks an unsynced GPS time with a tilde', (tester) async {
      final now = DateTime(2026, 5, 29, 14, 32, 10);
      await _pump(
        tester,
        race: _race(),
        prediction: _prediction(),
        wind: _wind(),
        boat: _boat(now),
        status: const Connected(),
        tick: now,
        trueTime: TrueTimeReading(
          utc: DateTime(2026, 5, 29, 14, 32, 7),
          source: TrueTimeSource.wallClockUnsynced,
        ),
      );

      expect(find.text('~14:32:07'), findsOneWidget);
    });

    testWidgets('shows the placeholder when no time source yet', (
      tester,
    ) async {
      final now = DateTime(2026, 5, 29, 14, 32, 10);
      await _pump(
        tester,
        race: _race(),
        prediction: _prediction(),
        wind: _wind(),
        boat: _boat(now),
        status: const Connected(),
        tick: now,
        trueTime: const TrueTimeReading(
          utc: null,
          source: TrueTimeSource.none,
        ),
      );

      expect(find.text('--:--:--'), findsOneWidget);
    });

    testWidgets('critical warning → banner és letompított grid', (
      tester,
    ) async {
      final now = DateTime(2026, 5, 29, 14, 32, 10);
      await _pump(
        tester,
        race: _race(),
        prediction: _prediction(),
        wind: _wind(),
        boat: _boat(now),
        status: const Connected(),
        tick: now,
        warnings: const [GpsSignalLost()],
      );

      expect(find.text('Nincs GPS-jel'), findsOneWidget);
      expect(_liveGridOpacity(tester), 0.4);
    });

    testWidgets('info warning → banner, a grid nem tompul', (tester) async {
      final now = DateTime(2026, 5, 29, 14, 32, 10);
      await _pump(
        tester,
        race: _race(),
        prediction: _prediction(),
        wind: _wind(),
        boat: _boat(now),
        status: const Connected(),
        tick: now,
        warnings: const [WindShiftTrendInsufficient()],
      );

      expect(find.text('Kevés széladat a trendhez'), findsOneWidget);
      expect(_liveGridOpacity(tester), 1.0);
    });

    testWidgets('service-hiba → hibasor a státuszsor után', (tester) async {
      final now = DateTime(2026, 5, 29, 14, 32, 10);
      await _pump(
        tester,
        race: _race(),
        prediction: _prediction(),
        wind: _wind(),
        boat: _boat(now),
        status: const Connected(),
        tick: now,
        serviceError: 'boom',
      );

      expect(find.text('Háttér-engine hiba: boom'), findsOneWidget);
    });

    testWidgets('nincs service-hiba → nincs hibasor', (tester) async {
      final now = DateTime(2026, 5, 29, 14, 32, 10);
      await _pump(
        tester,
        race: _race(),
        prediction: _prediction(),
        wind: _wind(),
        boat: _boat(now),
        status: const Connected(),
        tick: now,
      );

      expect(find.textContaining('Háttér-engine hiba'), findsNothing);
    });
  });
}
