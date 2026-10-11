import 'dart:async';
import 'dart:developer' as developer;

import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:phone/engine/race_engine_host.dart';
import 'package:phone/engine/timer_factory.dart';
import 'package:phone/providers/engine_session_provider.dart';
import 'package:phone/providers/engine_session_state.dart';
import 'package:phone/providers/instruments_race_selector.dart';

/// A háttér-engine életciklusa (ADR 0054 D5, D6, E3; ADR 0017 A12 utódja):
/// a session-állapotra indítja, átveszi vagy leállítja a hostot, a verseny
/// státusz-átmeneteire parancsot küld, és az előtérbe kerüléskor egyezteti
/// a sessiont a valóban futó service-szel.
///
/// Számon tartja, melyik verseny van az engine-ben, mert a UI-ban
/// kiválasztott verseny nem feltétlenül azonos vele: egy szabad módban futó
/// engine-nek a „Rajt" a teljes versenyt adja át, egy már ismert versenynek
/// csak a rajtidőt. A forrás az engine pillanatképe (`raceId`,
/// `raceStatus`); egy parancs után az első pillanatképig a küldött verseny.
///
/// A „nap versenye" (ADR 0055 D5, T4) a próba találatakor és a versenyek
/// vagy az előtér változásakor dönt az engine versenyéről, amíg az engine
/// nem versenyez, és a versenyét nem a felhasználó adta át („Élő nézet",
/// kézi „Rajt"): az erősebb. Az engine által indított rajtot a DB-be
/// átveteti (ADR 0055 D6).
class RaceEngineLifecycle {
  /// Életciklus a [host]-hoz és a [session] állapotgéphez. A
  /// [selectInstrumentsRace] adja a nap versenyét; a [readLastRecordingAt]
  /// és az [isRaceResumable] egy visszatöltött `active` verseny
  /// folytatásáról dönt.
  RaceEngineLifecycle({
    required RaceEngineHost host,
    required EngineSessionNotifier session,
    required Race? Function() readActiveRace,
    required Future<Polar?> Function() loadPolar,
    required void Function(String? error) reportServiceError,
    required Future<void> Function(String raceId, DateTime at)
    persistEngineFinish,
    required Future<void> Function(String raceId, DateTime at)
    persistEngineStart,
    required Future<InstrumentsRaceSelection> Function() selectInstrumentsRace,
    required LastRecordingReader readLastRecordingAt,
    required Duration adoptTimeout,
    IsRaceResumable isRaceResumable = const IsRaceResumable(),
    DateTime Function() now = DateTime.now,
    TimerFactory createTimer = Timer.new,
  }) : _host = host,
       _session = session,
       _readActiveRace = readActiveRace,
       _loadPolar = loadPolar,
       _reportServiceError = reportServiceError,
       _persistEngineFinish = persistEngineFinish,
       _persistEngineStart = persistEngineStart,
       _selectInstrumentsRace = selectInstrumentsRace,
       _readLastRecordingAt = readLastRecordingAt,
       _adoptTimeout = adoptTimeout,
       _isRaceResumable = isRaceResumable,
       _now = now,
       _createTimer = createTimer {
    _snapshots = _host.snapshots.listen(_onSnapshot);
    _idleStops = _host.idleStops.listen((_) => _onEngineIdleStop());
  }

  final RaceEngineHost _host;
  final EngineSessionNotifier _session;
  final Race? Function() _readActiveRace;
  final Future<Polar?> Function() _loadPolar;
  final void Function(String? error) _reportServiceError;
  final Future<void> Function(String raceId, DateTime at) _persistEngineFinish;
  final Future<void> Function(String raceId, DateTime at) _persistEngineStart;
  final Future<InstrumentsRaceSelection> Function() _selectInstrumentsRace;
  final LastRecordingReader _readLastRecordingAt;
  final Duration _adoptTimeout;
  final IsRaceResumable _isRaceResumable;
  final DateTime Function() _now;
  final TimerFactory _createTimer;
  late final StreamSubscription<RaceSnapshot> _snapshots;
  late final StreamSubscription<void> _idleStops;

  bool _isRunning = false;
  // A host ténylegesen fut (sikeres indítás vagy átvétel); csak ekkor
  // jelenti egy nem futó service, hogy az engine közben leállt.
  bool _isHostUp = false;
  // Minden indítás és leállítás új generáció: egy késve befejeződő
  // aszinkron lépés egy közben jött leállítás után már nem nyúl semmihez.
  int _generation = 0;
  Race? _engineRace;
  // Minden versenyváltásra nő: egy késve érkező döntés nem írja felül egy
  // közben kiküldött parancs versenyét.
  int _engineRaceVersion = 0;
  // Az engine versenyét a nap versenyének szabálya választotta (vagy
  // szabad mód); a felhasználó átadását a szabály nem írja felül.
  bool _isEngineRaceFromRule = false;
  // Egy átvett engine versenye, amit a UI nem ismer (az előző
  // app-folyamatban adták át): a szabály ezt sem írja felül.
  String? _adoptedRaceId;
  // Az átvételkori verzió: az első pillanatkép csak akkor dönt a verseny
  // gazdájáról, ha azóta nem ment parancs (az a pillanatkép előtti).
  int _adoptedVersion = -1;
  // Az engine legutóbbi pillanatképének státusza; a parancs utáni első
  // pillanatképig a küldött verseny (`_engineRace`) dönt.
  RaceStatus? _snapshotStatus;
  String? _snapshotRaceId;
  bool _hasSnapshotSinceCommand = false;
  // A már lezártként kezelt versenyek: egy késve érkező, még a lezárt
  // versenyt mutató pillanatkép nem zárja le újra.
  final Set<String> _handledFinishIds = {};
  // Az engine által indított, a DB-be már átvett rajtok.
  final Set<String> _handledStartIds = {};
  bool _hasSnapshotSinceAttach = false;
  bool _isAwaitingAdoptedSnapshot = false;
  Timer? _adoptWatchdog;
  // Minden háttérbe kerülés növeli: egy előtte indult, késve befejeződő
  // egyeztetés már nem jelezhet előteret.
  int _pauseCount = 0;

  /// A session-állapot változása (a provider `ref.listen`-je hívja).
  void onSessionChanged(EngineSessionState? previous, EngineSessionState next) {
    final wasRunning = previous is EngineRunning;
    if (next is EngineRunning && !wasRunning) {
      _start(next.cause);
    } else if (next is! EngineRunning && wasRunning) {
      _stop();
    }
  }

  /// Az app előtérbe került: előbb egyeztet a valóban futó service-szel
  /// (egy közben, magától leállt engine; vagy egy korábbi app-folyamatból
  /// futó, átvehető engine), csak utána indulhat a próba.
  Future<void> onAppResumed() async {
    final pauseCount = _pauseCount;
    try {
      await _reconcileWithService(pauseCount);
    } on Object catch (error) {
      developer.log('engine reconcile failed: $error', name: 'Lifecycle');
    }
    // Az egyeztetés alatt az app újra háttérbe került: nem vagyunk előtérben.
    if (pauseCount != _pauseCount) return;
    _session.appResumed();
    // Egy átvett, még néma engine figyelése a háttér alatt szünetelt.
    if (_isAwaitingAdoptedSnapshot) _armAdoptWatchdog(_generation);
    // A háttér alatt a nap is változhatott (éjfél, lejárt ablak).
    await _reevaluateInstrumentsRace();
  }

  /// A versenyek változtak a DB-ben (új, szerkesztett vagy törölt verseny):
  /// a nap versenye újra dönt (ADR 0055 D5, D8).
  void onRacesChanged() => unawaited(_reevaluateInstrumentsRace());

  /// Az app háttérbe került: a próba szünetel. Az átvétel figyelése is: a
  /// háttérben álló UI nem kap pillanatképet, így egy lejárt időzítő egy
  /// egészséges engine-t indítana újra.
  void onAppPaused() {
    _pauseCount++;
    _adoptWatchdog?.cancel();
    _adoptWatchdog = null;
    _session.appPaused();
  }

  /// A kiválasztott verseny változása. Csak ugyanannak a versenynek a
  /// státusz-átmenete számít; a kiválasztás cseréje nem parancs (azt a
  /// [handOver] adja át). Kivétel a `null` → `active` (pl. boot-restore).
  void onActiveRaceChanged(Race? previous, Race? next) {
    if (next == null) return;
    if (previous == null) {
      _onRaceRestored(next);
      return;
    }
    if (previous.id != next.id || previous.status == next.status) return;
    switch (next.status) {
      case RaceStatus.active:
        _onRaceStarted(next);
      case RaceStatus.finished:
        _onRaceFinished(next);
      case RaceStatus.notStarted:
        break;
    }
  }

  /// Az „Élő nézet": a [race] átadása az engine-nek. Futó engine-nek
  /// `race` parancs megy (ADR 0054 D6), különben az engine elindul. A
  /// hívó előbb kiválasztja a [race]-t (`activeRaceProvider`): álló
  /// engine a kiválasztottal indul. Egy folyamatban lévő versenyt nem
  /// cserél le, és nem is küldi újra (az engine eldobná, ADR 0017 A10).
  /// Az átadott versenyt a nap versenyének szabálya nem írja felül (ADR
  /// 0055 „Pontosítás (T4)"). Az U2 óta nincs UI-hívója (az „Élő nézet"
  /// megszűnt); a gazda-szabállyal együtt az U4 váltója szünteti meg.
  void handOver(Race race) {
    if (!_isRunning) {
      _session.startManually();
      return;
    }
    if (_isEngineRacing) return;
    _sendRace(race.status == RaceStatus.finished ? null : race);
  }

  /// A feliratkozások és az időzítő lezárása.
  void dispose() {
    // Egy még futó aszinkron lépés eredménye már senkinek nem szól.
    _generation++;
    _adoptWatchdog?.cancel();
    unawaited(_snapshots.cancel());
    unawaited(_idleStops.cancel());
  }

  // Folyamatban lévő verseny van az engine-ben: nem cserélhető (A10). A
  // forrás az engine pillanatképe, mert az engine az utolsó bójánál maga
  // is lezárhatja a versenyt, amiről a UI-oldali kiválasztás nem tud.
  bool get _isEngineRacing => _hasSnapshotSinceCommand
      ? _snapshotStatus == RaceStatus.active
      : _engineRace?.status == RaceStatus.active;

  // Az engine versenyének azonosítója (`null`: szabad mód vagy ismeretlen).
  String? get _engineRaceId =>
      _hasSnapshotSinceCommand ? _snapshotRaceId : _engineRace?.id;

  Future<void> _reconcileWithService(int pauseCount) async {
    final generation = _generation;
    final isServiceRunning = await _host.isRunning();
    // Közben háttérbe került az app: a következő előtérnél döntünk, nehogy
    // egy háttérben élesített átvételi figyelés újraindítson.
    if (generation != _generation || pauseCount != _pauseCount) return;
    if (_isRunning && _isHostUp && !isServiceRunning) {
      // Az engine háttérben leállt (10 perc), és a jelzése elveszett.
      _session.stopAfterIdle();
    } else if (!_isRunning && isServiceRunning) {
      _session.adoptRunningEngine();
    }
  }

  void _start(EngineStartCause cause) {
    _isRunning = true;
    final generation = ++_generation;
    _setEngineRace(null);
    switch (cause) {
      case EngineStartCause.user:
        _setEngineRace(_selectedRace());
        unawaited(_startHost(generation));
      case EngineStartCause.gatewayFound:
        unawaited(_startWithInstrumentsRace(generation));
      case EngineStartCause.adopted:
        _adopt(generation);
    }
  }

  // A kiválasztott verseny a felhasználó indításához (befejezett helyett
  // szabad mód).
  Race? _selectedRace() {
    final race = _readActiveRace();
    if (race == null || race.status == RaceStatus.finished) return null;
    return race;
  }

  // A próba találata: a nap versenye (ADR 0055 D5): egy friss felvételű
  // `active` verseny (app-újraindítás verseny közben, akár éjfél után is),
  // különben a mai tervezett verseny, különben szabad mód.
  Future<void> _startWithInstrumentsRace(int generation) async {
    final version = _engineRaceVersion;
    final selection = await _selectSafely();
    if (generation != _generation) return;
    // Egy közben jött parancs („Élő nézet", „Rajt") erősebb a döntésnél.
    if (version == _engineRaceVersion) {
      _setEngineRace(selection?.dayRace, isFromRule: true);
    }
    await _startHost(generation);
  }

  // Egy olvasási hiba (pl. DB) a kiválasztás helyett szabad módot ad.
  Future<InstrumentsRaceSelection?> _selectSafely() async {
    try {
      return await _selectInstrumentsRace();
    } on Object catch (error) {
      developer.log(
        'instruments race select failed: $error',
        name: 'Lifecycle',
      );
      return null;
    }
  }

  // A nap versenyének újradöntése egy futó, nem versenyző engine-en. A
  // szabály által választott (vagy szabad módú) engine a nap versenyét
  // kapja; egy felhasználó által átadott verseny csak a friss
  // (szerkesztett) példányát, amíg el nem indult (ADR 0055 D8).
  Future<void> _reevaluateInstrumentsRace() async {
    if (!_canReevaluate) return;
    final generation = _generation;
    final version = _engineRaceVersion;
    final selection = await _selectSafely();
    if (selection == null || !_canReevaluate) return;
    if (generation != _generation || version != _engineRaceVersion) return;
    final isRuleOwned = _isRuleOwned;
    final next = isRuleOwned
        ? selection.dayRace
        : _freshNotStartedCopy(
            selection.races,
            _engineRace?.id ?? _adoptedRaceId,
          );
    if (!isRuleOwned && next == null) return;
    if (next == _engineRace) return;
    _sendRace(next, isFromRule: isRuleOwned);
  }

  bool get _canReevaluate =>
      _isRunning &&
      _isHostUp &&
      !_isAwaitingAdoptedSnapshot &&
      !_isEngineRacing;

  // A szabályé az engine versenye, ha ő választotta, vagy ha a lifecycle
  // szerint nincs verseny az engine-ben. A pillanatképet szándékosan nem
  // nézzük: egy átadás előtt készült, `raceId` nélküli pillanatkép egy
  // másodpercig szabad módot mutatna, és a szabály felülírná az átadott
  // versenyt.
  bool get _isRuleOwned =>
      _isEngineRaceFromRule || (_engineRace == null && _adoptedRaceId == null);

  static Race? _freshNotStartedCopy(List<Race> races, String? raceId) {
    for (final race in races) {
      if (race.id == raceId) {
        return race.status == RaceStatus.notStarted ? race : null;
      }
    }
    return null;
  }

  Future<bool> _isRecent(Race race) async {
    DateTime? lastRecordedAt;
    try {
      lastRecordedAt = await _readLastRecordingAt(race.id);
    } on Object catch (error) {
      // DB-hiba: csak a rajtidő számít.
      developer.log('last recording read failed: $error', name: 'Lifecycle');
    }
    return _isRaceResumable(
      race: race,
      lastRecordedAt: lastRecordedAt,
      now: _now(),
    );
  }

  Future<void> _startHost(int generation) async {
    final polar = await _loadPolar();
    if (generation != _generation) return;
    // A polár betöltése alatt jöhetett `race` parancs vagy „Rajt": a host
    // a mostani versennyel induljon, különben felülírná a függő versenyét.
    final error = await _host.start(race: _engineRace, polar: polar);
    if (generation != _generation) {
      // A leállítás az indítás közben jött: a már elindult service-t
      // leállítjuk, hogy ne maradjon árva, figyelés nélküli engine.
      if (!_isRunning && error == null) unawaited(_host.stop());
      return;
    }
    _isHostUp = error == null;
    _reportServiceError(error);
    if (error != null) _session.startFailed();
  }

  // Egy futó engine átvétele: a kiválasztott `active` verseny a
  // legvalószínűbb versenye. Ha [_adoptTimeout]-on belül nem jön tőle
  // pillanatkép (a main↔task csatorna nem áll fel újra), a mai útra esünk
  // vissza: leállítás és újraindítás.
  void _adopt(int generation) {
    final selected = _readActiveRace();
    _setEngineRace(selected?.status == RaceStatus.active ? selected : null);
    _adoptedVersion = _engineRaceVersion;
    _hasSnapshotSinceAttach = false;
    _isAwaitingAdoptedSnapshot = true;
    _host.attach(race: _engineRace);
    _isHostUp = true;
    _armAdoptWatchdog(generation);
  }

  void _armAdoptWatchdog(int generation) {
    _adoptWatchdog?.cancel();
    _adoptWatchdog = _createTimer(
      _adoptTimeout,
      () => _onAdoptTimeout(generation),
    );
  }

  void _onAdoptTimeout(int generation) {
    _adoptWatchdog = null;
    if (generation != _generation || _hasSnapshotSinceAttach) return;
    developer.log('adopted engine silent, restarting', name: 'Lifecycle');
    _isAwaitingAdoptedSnapshot = false;
    _isHostUp = false;
    unawaited(_startWithInstrumentsRace(generation));
  }

  void _stop() {
    _isRunning = false;
    _isHostUp = false;
    _generation++;
    _setEngineRace(null);
    _isAwaitingAdoptedSnapshot = false;
    _adoptWatchdog?.cancel();
    _adoptWatchdog = null;
    unawaited(_host.stop());
  }

  void _onEngineIdleStop() {
    if (!_isRunning) return;
    // A service már leállt; a session-váltás utáni `stop` ártalmatlan.
    _isHostUp = false;
    _session.stopAfterIdle();
  }

  void _onRaceStarted(Race race) {
    if (!_isRunning) {
      // Kézi „Rajt" futó engine nélkül: maga indít (ADR 0054 D5); a kezdő
      // verseny a már aktív kiválasztott.
      _session.startManually();
      return;
    }
    // Egy másik, folyamatban lévő versenyt az engine nem cserél le (A10):
    // ha a lifecycle mégis átállna, a két cél-parancs elcsúszna.
    if (_isEngineRacing && _engineRaceId != race.id) return;
    final startedAt = race.startedAt;
    if (_engineRaceId == race.id && startedAt != null) {
      _host.sendStartCommand(startedAt);
      _setEngineRace(race);
    } else {
      _sendRace(race);
    }
  }

  // `null` → `active` (pl. boot-restore), miután a próba már szabad
  // módban elindította az engine-t (a restore lassabb lehet egy LAN-os
  // TCP-kapcsolódásnál): friss felvételnél a verseny folytatódik.
  void _onRaceRestored(Race race) {
    // Ha az engine (az átvett is) már versenyez, a pillanatképe a mérvadó:
    // egy restore nem állíthatja át a lifecycle-t egy másik versenyre.
    if (!_isRunning || _engineRaceId != null || _isEngineRacing) return;
    if (race.status != RaceStatus.active) return;
    unawaited(_resumeRestoredRace(race));
  }

  Future<void> _resumeRestoredRace(Race race) async {
    final generation = _generation;
    final version = _engineRaceVersion;
    if (!await _isRecent(race)) return;
    if (generation != _generation || version != _engineRaceVersion) return;
    _sendRace(race);
  }

  void _onRaceFinished(Race race) {
    if (!_isRunning || _engineRaceId != race.id) return;
    _handledFinishIds.add(race.id);
    final finishedAt = race.finishedAt;
    if (finishedAt != null) _host.sendFinishCommand(finishedAt);
    // A cél után az engine szabad módban fut tovább (ADR 0054 D5), és a
    // nap következő versenye a szabályé.
    _sendRace(null, isFromRule: true);
  }

  void _sendRace(Race? race, {bool isFromRule = false}) {
    _host.sendRaceCommand(race);
    _setEngineRace(race, isFromRule: isFromRule);
  }

  // Egy parancs után a következő pillanatképig a küldött verseny számít.
  void _setEngineRace(Race? race, {bool isFromRule = false}) {
    _engineRace = race;
    _isEngineRaceFromRule = isFromRule;
    _adoptedRaceId = null;
    _engineRaceVersion++;
    _hasSnapshotSinceCommand = false;
  }

  void _onSnapshot(RaceSnapshot snapshot) {
    if (!_isRunning) return;
    final isFirstAdoptedSnapshot = _isAwaitingAdoptedSnapshot;
    _hasSnapshotSinceAttach = true;
    _isAwaitingAdoptedSnapshot = false;
    _adoptWatchdog?.cancel();
    _adoptWatchdog = null;
    _snapshotStatus = snapshot.raceStatus;
    _snapshotRaceId = snapshot.raceId;
    _hasSnapshotSinceCommand = true;
    if (isFirstAdoptedSnapshot && _engineRaceVersion == _adoptedVersion) {
      _alignAdoptedRace(snapshot.raceId);
    }
    final raceId = snapshot.raceId;
    final raceStartedAt = snapshot.raceStartedAt;
    if (snapshot.raceStatus == RaceStatus.active &&
        raceId != null &&
        raceStartedAt != null &&
        _handledStartIds.add(raceId)) {
      // Egy kézi rajtnál a DB már `active`: az átvétel ott no-op.
      _onEngineStartedRace(raceId, raceStartedAt);
    }
    if (snapshot.raceStatus == RaceStatus.finished &&
        raceId != null &&
        _handledFinishIds.add(raceId)) {
      // A pillanatkép a valódi célidőt viszi; késve feldolgozva is az kell.
      _onEngineFinishedRace(
        raceId,
        snapshot.raceFinishedAt ?? snapshot.tickTime,
      );
    }
  }

  // Az engine az utolsó bójánál maga zárta le a versenyt („Cél" nélkül). A
  // DB-ben is lezárjuk, különben a verseny `active` maradna, és a 6 órás
  // folytatás a kikötőben újraindítaná; az engine-t pedig szabad módba
  // engedjük, hogy a 10 perces leállás működjön.
  void _onEngineFinishedRace(String raceId, DateTime at) {
    // Ha közben egy másik verseny ment át (pl. „Élő nézet" egy átvett
    // engine-re), azt nem vesszük ki; a persist ettől még fut.
    final sent = _engineRace;
    if (sent == null || sent.id == raceId) _sendRace(null, isFromRule: true);
    unawaited(() async {
      try {
        await _persistEngineFinish(raceId, at);
      } on Object catch (error) {
        developer.log('engine finish save failed: $error', name: 'Lifecycle');
      }
    }());
  }

  // Az engine a tervezett rajtidőben maga indította a versenyt (ADR 0055
  // D6): a DB-be a UI veszi át, a pillanatkép rajtidejével.
  void _onEngineStartedRace(String raceId, DateTime startedAt) {
    unawaited(() async {
      try {
        await _persistEngineStart(raceId, startedAt);
      } on Object catch (error) {
        developer.log('engine start save failed: $error', name: 'Lifecycle');
      }
    }());
  }

  // Az átvételkor a lifecycle csak tippel (a kiválasztott aktív verseny
  // vagy semmi); az első pillanatkép mondja meg, mi fut valójában, és így
  // azt is, kié a verseny: szabad módban a szabályé, egy ismeretlen
  // versennyel a felhasználóé (egy korábbi átadásból). A pillanatkép
  // státuszát nem bántjuk, ezért nem a `_setEngineRace`-szel. Csak akkor
  // fut, ha az átvétel óta nem ment parancs.
  void _alignAdoptedRace(String? raceId) {
    if (raceId == null) {
      _engineRace = null;
      _isEngineRaceFromRule = true;
      _adoptedRaceId = null;
      _engineRaceVersion++;
    } else if (_engineRace?.id != raceId) {
      _engineRace = null;
      _isEngineRaceFromRule = false;
      _adoptedRaceId = raceId;
      _engineRaceVersion++;
    }
  }
}
