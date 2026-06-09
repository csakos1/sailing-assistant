import 'dart:async';

import 'package:data/src/engine/race_snapshot.dart';
import 'package:data/src/nmea/client/raw_nmea_line_source.dart';
import 'package:domain/domain.dart';

/// A háttér-adatfolyam egy-tulajdonos orchestrátora (ADR 0017 D1).
///
/// Plain-Dart, Riverpod nélkül: az injektált [NmeaStream]-re iratkozik, a
/// domain-eseményeket a [BoatStateReducer] / [WindHistoryReducer]
/// segítségével élő állapottá foldol, a `tickSource` (default 1 Hz) minden
/// ütésénél újraszámolja a wind-shift trendet és a [MarkPrediction]-t, és
/// [RaceSnapshot]-ot emittál. A nyers mondatokat — ha a forrás egyúttal
/// [RawNmeaLineSource] — az injektált [TelemetryLogger]-nek adja át.
///
/// A `domain` + `data` rétegre épül, a hoszt (foreground service / izolátum)
/// nem szivárog ide (ADR 0016 D7) — ezért közvetlenül, `ProviderContainer`
/// nélkül replay-tesztelhető.
class RaceEngine {
  /// Engine az injektált forrással és telemetria-loggerrel. A `tickSource`
  /// teszt-seam: ha `null`, belső 1 Hz-es `Stream.periodic` jár.
  RaceEngine({
    required NmeaStream nmeaStream,
    required TelemetryLogger telemetryLogger,
    Stream<DateTime>? tickSource,
    Duration windWindow = const Duration(minutes: 10),
    DateTime Function() now = DateTime.now,
  }) : _nmeaStream = nmeaStream,
       _telemetryLogger = telemetryLogger,
       _windWindow = windWindow,
       _now = now,
       _tickSource =
           tickSource ??
           Stream<DateTime>.periodic(const Duration(seconds: 1), (_) => now());

  final NmeaStream _nmeaStream;
  final TelemetryLogger _telemetryLogger;
  final Stream<DateTime> _tickSource;
  final Duration _windWindow;
  final DateTime Function() _now;

  // Állapotmentes, megosztható domain-egységek (const példányok).
  static const _boatReducer = BoatStateReducer();
  static const _windReducer = WindHistoryReducer();
  static const _trend = CalculateWindShiftTrend();
  static const _predict = ComputeMarkPrediction();

  final StreamController<RaceSnapshot> _snapshots =
      StreamController<RaceSnapshot>.broadcast();

  // Élő, foldolt állapot — egy-tulajdonos: csak az engine írja.
  late BoatState _boatState;
  WindData? _wind;
  List<WindObservation> _windHistory = const <WindObservation>[];
  int _eventCount = 0;
  Race? _race;

  // A mark-rounding detektor (stateful, egy aktív bójához egy minimum-
  // profil). Megkerüléskor reseteljük; a léptetést a _maybeRoundMark
  // végzi (ADR 0017 A11).
  final MarkRoundingDetector _markRoundingDetector = MarkRoundingDetector();

  StreamSubscription<DomainEvent>? _eventSub;
  StreamSubscription<String>? _rawSub;
  StreamSubscription<DateTime>? _tickSub;

  /// A tick-enkénti pillanatképek folyama (a hoszt / UI-tükör fogyasztja).
  Stream<RaceSnapshot> get snapshots => _snapshots.stream;

  /// Elindítja az adatfolyamot a `race`-hez: feliratkozik az eseményekre
  /// (fold) és — ha a forrás [RawNmeaLineSource] — a nyers sorokra
  /// (telemetria), elindítja a tick-et, majd csatlakozik a forráshoz. A
  /// [BoatState] az app-órából seedel.
  Future<void> start(Race race) async {
    _race = race;
    _boatState = BoatState(lastUpdate: _now());

    _eventSub = _nmeaStream.events.listen(_onEvent);
    if (_nmeaStream case final RawNmeaLineSource rawSource) {
      _rawSub = rawSource.rawLines.listen(_onRawLine);
    }
    _tickSub = _tickSource.listen(_onTick);

    await _nmeaStream.connect();
  }

  /// Leállítja a feliratkozásokat és a tick-et, majd lekapcsolja a forrást. A
  /// telemetria záró flush-e a [dispose]-ban történik.
  Future<void> stop() async {
    await _eventSub?.cancel();
    await _rawSub?.cancel();
    await _tickSub?.cancel();
    _eventSub = null;
    _rawSub = null;
    _tickSub = null;
    await _nmeaStream.disconnect();
  }

  /// Végleg elenged: [stop], a telemetria-logger záró flush-e, és a
  /// snapshot-controller zárása. Idempotens. Az injektált [NmeaStream] teljes
  /// felszabadítása a composition root dolga (az interfészen nincs `dispose`).
  Future<void> dispose() async {
    await stop();
    await _telemetryLogger.dispose();
    if (!_snapshots.isClosed) {
      await _snapshots.close();
    }
  }

  /// A UI-tól érkező Start parancs alkalmazása az engine saját `_race`-én
  /// (A10/A13): `notStarted → active` az `at` időbélyeggel. No-op, ha
  /// nincs race vagy már nem `notStarted` — idempotens, a dup-parancs nem
  /// dob (a `Race.start` assertje csak notStartedre enged). A rounding
  /// által léptetett `activeMarkIndex` (induláskor 0) érintetlen marad.
  void applyStartCommand(DateTime at) {
    final race = _race;
    if (race == null || race.status != RaceStatus.notStarted) {
      return;
    }
    _race = race.start(at: at);
  }

  /// A UI-tól érkező Finish parancs alkalmazása (A10/A13):
  /// `active → finished` az `at` időbélyeggel. No-op, ha nincs race vagy
  /// nem `active`. A `finish` az indexet a domain-szabály szerint a
  /// végére állítja (`index == marks.length`), így az aktív bója `null`,
  /// és a mark-rounding nem léptet tovább.
  void applyFinishCommand(DateTime at) {
    final race = _race;
    if (race == null || race.status != RaceStatus.active) {
      return;
    }
    _race = race.finish(at: at);
  }

  // Egyetlen esemény befoldolása az élő állapotba.
  void _onEvent(DomainEvent event) {
    _eventCount++;
    _boatState = _boatReducer(_boatState, event, _now());
    if (event case WindEvent(:final data)) {
      _wind = data;
      final twd = data.trueDirectionGround;
      if (twd != null) {
        _windHistory = _windReducer(
          _windHistory,
          WindObservation(twd: twd, timestamp: data.timestamp),
        );
      }
    }
  }

  // Egy nyers sor telemetria-rekordként. Az üres sort kihagyjuk (a
  // TelemetryRecord nem enged üres rawSentence-t).
  void _onRawLine(String line) {
    final race = _race;
    if (race == null || line.isEmpty) {
      return;
    }
    unawaited(
      _telemetryLogger.log(
        TelemetryRecord(raceId: race.id, timestamp: _now(), rawSentence: line),
      ),
    );
  }

  // 1 Hz recompute: trend → prediction → snapshot emit.
  void _onTick(DateTime tick) {
    final race = _race;
    if (race == null || _snapshots.isClosed) {
      return;
    }
    // A predikció előtt léptetjük az aktív bóját, ha a hajó körözte (csak
    // active alatt, ADR 0017 A11) — a léptetett race-re prediktálunk.
    final steppedRace = _maybeRoundMark(race, tick);
    _race = steppedRace;

    final trend = _trend(history: _windHistory, window: _windWindow, now: tick);
    final prediction = _predict(
      activeMark: steppedRace.activeMarkOrNull,
      nextMark: steppedRace.nextMarkOrNull,
      boatState: _boatState,
      trend: trend,
      now: tick,
    );
    _snapshots.add(
      RaceSnapshot(
        eventCount: _eventCount,
        boatState: _boatState,
        connectionStatus: _nmeaStream.currentStatus,
        raceStatus: steppedRace.status,
        tickTime: tick,
        wind: _wind,
        prediction: prediction,
        windShiftTrend: trend,
      ),
    );
  }

  // A mark-rounding detektor egy tickje (ADR 0017 A11). Csak active
  // státusz + ismert pozíció + aktív bója esetén léptet; megkerüléskor a
  // következő bójára vált és reseteli a detektort. DB-visszaírás nincs
  // (ADR 0016 D6) — a progressziót a telemetria + snapshot rögzíti.
  Race _maybeRoundMark(Race race, DateTime tick) {
    if (race.status != RaceStatus.active) {
      return race;
    }
    final position = _boatState.position;
    final activeMark = race.activeMarkOrNull;
    if (position == null || activeMark == null) {
      return race;
    }
    if (_markRoundingDetector.tick(position, activeMark)) {
      _markRoundingDetector.reset();
      return race.roundCurrentMark(at: tick);
    }
    return race;
  }
}
