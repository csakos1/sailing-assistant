import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/app/localization_delegates.dart';
import 'package:phone/app/true_time.dart';
import 'package:phone/features/live_race/free_mode/free_mode_view.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:phone/providers/active_warnings_provider.dart';
import 'package:phone/providers/engine_service_error_provider.dart';
import 'package:phone/providers/engine_session_provider.dart';
import 'package:phone/providers/engine_session_state.dart';
import 'package:phone/providers/gps_time_reading_provider.dart';
import 'package:phone/providers/race_snapshot_provider.dart';
import 'package:phone/providers/tick_provider.dart';

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
}

const _running = EngineRunning(cause: EngineStartCause.gatewayFound);

final _now = DateTime.utc(2026, 7, 30, 9, 10);

// 3,3 m/s = 6,4 kn; 3,14 m/s = 6,1 kn; 7,3 m/s = 14,2 kn.
const _stw = Speed(metersPerSecond: 3.3);
const _sog = Speed(metersPerSecond: 3.14);

RaceSnapshot _snapshot({
  ConnectionStatus status = const Connected(),
  Speed? stw = _stw,
  Speed? sog = _sog,
  DateTime? lastUpdate,
  int eventCount = 120,
  double? targetSpeedKnots = 6.8,
  double? targetVmgKnots = 6.2,
}) => RaceSnapshot(
  eventCount: eventCount,
  boatState: BoatState(
    lastUpdate: lastUpdate ?? _now,
    speedThroughWater: stw,
    speedOverGround: sog,
  ),
  connectionStatus: status,
  tickTime: _now,
  wind: WindData(
    apparentAngle: const Angle(degrees: 30),
    apparentSpeed: const Speed(metersPerSecond: 8),
    timestamp: _now,
    trueAngleWater: const Angle(degrees: 42),
    trueSpeedWater: const Speed(metersPerSecond: 7.3),
  ),
  targetSpeedKnots: targetSpeedKnots,
  vmgKnots: 5.8,
  targetVmgKnots: targetVmgKnots,
);

Future<void> _pump(
  WidgetTester tester, {
  required EngineSessionState session,
  required RaceSnapshot? snapshot,
  List<Warning> warnings = const [],
  TrueTimeReading? trueTime,
}) async {
  tester.view.physicalSize = const Size(412, 892);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final reading =
      trueTime ??
      TrueTimeReading(
        utc: DateTime(2026, 7, 30, 11, 10, 53),
        source: TrueTimeSource.gnss,
      );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        engineSessionProvider.overrideWith(() => _FixedSession(session)),
        raceSnapshotProvider.overrideWith(() => _FixedSnapshot(snapshot)),
        activeWarningsProvider.overrideWithValue(warnings),
        engineServiceErrorProvider.overrideWith((ref) => null),
        gpsTimeReadingProvider.overrideWith(
          (ref) => Stream<TrueTimeReading>.value(reading),
        ),
        tickProvider.overrideWith((ref) => Stream<DateTime>.value(_now)),
      ],
      child: MaterialApp(
        theme: foretackTheme,
        localizationsDelegates: phoneLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const FreeModeView(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Color? _colorOf(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text).first).style?.color;

double _gridOpacity(WidgetTester tester) => tester
    .widget<Opacity>(
      find.ancestor(of: find.text('STW'), matching: find.byType(Opacity)),
    )
    .opacity;

void main() {
  group('FreeModeView', () {
    testWidgets('live data: speed, target %, VMG, TWA and TWS', (
      tester,
    ) async {
      await _pump(tester, session: _running, snapshot: _snapshot());

      expect(find.text('Csatlakozva'), findsOneWidget);
      expect(find.text('11:10:53'), findsOneWidget);
      expect(find.text('STW'), findsOneWidget);
      expect(find.text('6,4'), findsOneWidget);
      // 6,41 / 6,8 = 94%.
      expect(find.text('94%'), findsOneWidget);
      expect(find.text('5,8'), findsOneWidget);
      expect(find.text('cél 6,2'), findsOneWidget);
      expect(find.text('42°'), findsOneWidget);
      expect(find.text('14,2'), findsOneWidget);
      expect(_gridOpacity(tester), 1.0);
    });

    testWidgets('has no bearing, no TWD and no separate SOG cell', (
      tester,
    ) async {
      await _pump(tester, session: _running, snapshot: _snapshot());

      expect(find.text('BEARING'), findsNothing);
      expect(find.text('TWD'), findsNothing);
      expect(find.text('SOG'), findsNothing);
      expect(find.text('6,1'), findsNothing);
    });

    testWidgets('falls back to SOG in the same cell without STW', (
      tester,
    ) async {
      await _pump(tester, session: _running, snapshot: _snapshot(stw: null));

      expect(find.text('SOG'), findsOneWidget);
      expect(find.text('STW'), findsNothing);
      expect(find.text('6,1'), findsOneWidget);
    });

    testWidgets('without a polar the target is a dim placeholder', (
      tester,
    ) async {
      await _pump(
        tester,
        session: _running,
        snapshot: _snapshot(targetSpeedKnots: null, targetVmgKnots: null),
      );

      final scheme = foretackTheme.colorScheme;
      expect(find.text('—'), findsOneWidget);
      expect(_colorOf(tester, '—'), scheme.outline);
      expect(find.textContaining('cél'), findsNothing);
      // A VMG maga a polartol fuggetlen.
      expect(find.text('5,8'), findsOneWidget);
    });

    testWidgets('searching: every value is a dim placeholder', (
      tester,
    ) async {
      await _pump(tester, session: const EngineProbing(), snapshot: null);

      final scheme = foretackTheme.colorScheme;
      expect(find.text('Hajó keresése…'), findsOneWidget);
      expect(find.text('--:--:--'), findsOneWidget);
      // STW, CEL-SEB., VMG, TWA, TWS.
      expect(find.text('—'), findsNWidgets(5));
      expect(_colorOf(tester, '—'), scheme.outline);
    });

    testWidgets('searching ignores a snapshot that still connects', (
      tester,
    ) async {
      await _pump(
        tester,
        session: _running,
        snapshot: _snapshot(status: const Connecting(), eventCount: 0),
      );

      expect(find.text('Hajó keresése…'), findsOneWidget);
      expect(find.text('6,4'), findsNothing);
    });

    testWidgets('lost: dimmed last values and the age of the data', (
      tester,
    ) async {
      await _pump(
        tester,
        session: _running,
        snapshot: _snapshot(
          status: const ConnectionError('Kapcsolat megszakadt'),
          lastUpdate: _now.subtract(const Duration(minutes: 1, seconds: 12)),
        ),
      );

      final warning = foretackTheme.extension<WarningColors>()!.warning;
      expect(find.text('Nincs kapcsolat'), findsOneWidget);
      expect(find.text('ADAT'), findsOneWidget);
      expect(find.text('1:12 perce'), findsOneWidget);
      expect(_colorOf(tester, '1:12 perce'), warning);
      expect(find.text('11:10:53'), findsNothing);
      expect(find.text('6,4'), findsOneWidget);
      expect(_gridOpacity(tester), closeTo(0.42, 1e-9));
    });

    testWidgets('a reconnect attempt keeps the lost state', (tester) async {
      await _pump(
        tester,
        session: _running,
        snapshot: _snapshot(
          status: const Connecting(),
          lastUpdate: _now.subtract(const Duration(seconds: 20)),
        ),
      );

      expect(find.text('Nincs kapcsolat'), findsOneWidget);
      expect(find.text('Hajó keresése…'), findsNothing);
      expect(find.text('0:20 perce'), findsOneWidget);
      expect(find.text('6,4'), findsOneWidget);
    });

    testWidgets('lost for over an hour shows hours', (tester) async {
      await _pump(
        tester,
        session: _running,
        snapshot: _snapshot(
          status: const Disconnected(),
          lastUpdate: _now.subtract(const Duration(hours: 1, minutes: 5)),
        ),
      );

      expect(find.text('1:05 órája'), findsOneWidget);
    });

    testWidgets('lost without any data shows no age', (tester) async {
      await _pump(
        tester,
        session: _running,
        snapshot: _snapshot(status: const Disconnected(), eventCount: 0),
      );

      expect(find.text('ADAT'), findsNothing);
      expect(find.text('--:--:--'), findsOneWidget);
    });

    testWidgets('a critical warning dims the grid more than a lost link', (
      tester,
    ) async {
      await _pump(
        tester,
        session: _running,
        snapshot: _snapshot(status: const Disconnected()),
        warnings: const [DepthWarning(1.8)],
      );

      expect(_gridOpacity(tester), closeTo(0.4, 1e-9));
    });

    testWidgets('leaves out the gateway warning the strip already shows', (
      tester,
    ) async {
      await _pump(
        tester,
        session: const EngineProbing(),
        snapshot: null,
        // Mesterseges par: elesben kapcsolat nelkul csak a gateway-warning
        // jon; a polar-warning azt mutatja, hogy a szuro csak azt dobja el.
        warnings: const [GatewayDisconnected(), PolarMissing()],
      );

      expect(find.text('Nincs kapcsolat a műszerekkel'), findsNothing);
      expect(find.text('Nincs polár-adat'), findsOneWidget);
      // A GatewayDisconnected kritikus, megis kimarad: nincs tompitas.
      expect(_gridOpacity(tester), 1.0);
    });

    testWidgets('marks old connected data as stale', (tester) async {
      await _pump(
        tester,
        session: _running,
        snapshot: _snapshot(
          lastUpdate: _now.subtract(const Duration(seconds: 10)),
        ),
      );

      expect(find.text('ELAVULT'), findsOneWidget);
    });

    testWidgets('marks an unsynced GPS time with a tilde', (tester) async {
      await _pump(
        tester,
        session: _running,
        snapshot: _snapshot(),
        trueTime: TrueTimeReading(
          utc: DateTime(2026, 7, 30, 11, 10, 53),
          source: TrueTimeSource.wallClockUnsynced,
        ),
      );

      expect(find.text('~11:10:53'), findsOneWidget);
    });

    testWidgets('stopped: no menu, the map stays', (tester) async {
      await _pump(tester, session: const EngineStopped(), snapshot: null);

      expect(find.text('Leállítva'), findsOneWidget);
      expect(find.byTooltip('Menü'), findsNothing);
      expect(find.byTooltip('Biztonsági térkép'), findsOneWidget);
    });

    testWidgets('stops the engine from the menu after a confirmation', (
      tester,
    ) async {
      await _pump(tester, session: _running, snapshot: _snapshot());

      await tester.tap(find.byTooltip('Menü'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Leállítás'));
      await tester.pumpAndSettle();
      expect(find.text('Műszerek leállítása'), findsOneWidget);
      await tester.tap(find.text('Leállítás').last);
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(FreeModeView)),
      );
      expect(container.read(engineSessionProvider), isA<EngineStopped>());
      expect(find.text('Leállítva'), findsOneWidget);
    });

    testWidgets('cancelling the confirmation keeps the engine running', (
      tester,
    ) async {
      await _pump(tester, session: _running, snapshot: _snapshot());

      await tester.tap(find.byTooltip('Menü'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Leállítás'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mégse'));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(FreeModeView)),
      );
      expect(container.read(engineSessionProvider), isA<EngineRunning>());
    });

    testWidgets('the map button sits at the right edge of the strip', (
      tester,
    ) async {
      await _pump(tester, session: _running, snapshot: _snapshot());

      final map = tester.getRect(find.byTooltip('Biztonsági térkép'));
      final menu = tester.getRect(find.byTooltip('Menü'));
      expect(map.right, closeTo(412 - 2, 0.5));
      expect(menu.right, lessThanOrEqualTo(map.left));
    });
  });
}
