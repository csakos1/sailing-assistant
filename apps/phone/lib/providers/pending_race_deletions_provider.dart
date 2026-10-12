import 'dart:async';
import 'dart:developer' as developer;

import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/providers/race_repository_provider.dart';
import 'package:phone/providers/timer_factory_provider.dart';

/// Ennyi ideig vonható vissza egy törlés: a „Verseny törölve" snackbar
/// látható ideje (ADR 0056 D6, `phone-ui-v1.md` §9).
const Duration raceDeletionUndoWindow = Duration(seconds: 5);

// A DB-törlés a snackbar után ennyivel később fut. A snackbar órája a
// belépő animáció (~250 ms) után indul, így egy az utolsó pillanatban
// megnyomott VISSZAVONÁS sem érhet egy már törölt versenyt.
const Duration _commitGrace = Duration(seconds: 1);

/// A késleltetett, visszavonható törlések (ADR 0056 D6).
///
/// Az állapot a felületről elrejtett versenyek azonosítóinak halmaza. A
/// `raceListProvider` ezeket kiszűri, így a verseny a megerősítés után
/// azonnal eltűnik a felületről, a DB-törlés viszont csak a visszavonási
/// ablak lejártakor fut.
///
/// Egy sikeresen törölt azonosító a halmazban marad: a lista streamje a
/// törlést aszinkron hozza, és addig a legutóbbi lista még tartalmazza a
/// versenyt — kikerülésekor a sor egy pillanatra visszavillanna. A halmaz
/// így egy munkamenet törléseivel nő, ami elhanyagolható.
///
/// Ha az app közben háttérbe kerül, a héj a
/// [PendingRaceDeletions.cancelAll]-t hívja: a törlés elmarad, a verseny
/// visszajön. Ez a biztonságos irány — egy bezárt app időzítője sem töröl,
/// a verseny a következő indításkor megvan.
final NotifierProvider<PendingRaceDeletions, Set<String>>
pendingRaceDeletionsProvider =
    NotifierProvider<PendingRaceDeletions, Set<String>>(
      PendingRaceDeletions.new,
    );

/// A [pendingRaceDeletionsProvider] állapota és műveletei.
class PendingRaceDeletions extends Notifier<Set<String>> {
  final Map<String, Timer> _timers = {};

  @override
  Set<String> build() {
    ref.onDispose(_cancelTimers);
    return const {};
  }

  /// Kiszűri a [raceId] versenyt, és a visszavonási ablak után törli.
  void schedule(String raceId) {
    _timers.remove(raceId)?.cancel();
    _timers[raceId] = ref.read(timerFactoryProvider)(
      raceDeletionUndoWindow + _commitGrace,
      () => unawaited(_commit(raceId)),
    );
    state = {...state, raceId};
  }

  /// Visszavonja a [raceId] függő törlését; `true`, ha volt mit. Ha már
  /// nincs függőben (pl. a törlés lefutott), nem tesz semmit.
  bool undo(String raceId) {
    final timer = _timers.remove(raceId);
    if (timer == null) return false;
    timer.cancel();
    state = {...state}..remove(raceId);
    return true;
  }

  /// Minden függő törlést visszavon; `true`, ha volt mit. A már
  /// véglegesített törlések rejtve maradnak.
  bool cancelAll() {
    if (_timers.isEmpty) return false;
    state = {...state}..removeAll(_timers.keys);
    _cancelTimers();
    return true;
  }

  Future<void> _commit(String raceId) async {
    if (_timers.remove(raceId) == null) return;
    final repository = ref.read(raceRepositoryProvider);
    try {
      // Az ablak alatt az engine egy tervezett versenyt el is indíthatott
      // (ADR 0055 D6): futó versenyt nem törlünk, mert az engine ír hozzá.
      final race = await repository.getRace(raceId);
      if (race?.status != RaceStatus.active) {
        await repository.delete(raceId);
        return;
      }
      developer.log('race delete skipped: active', name: 'RaceDeletion');
    } on Object catch (error) {
      developer.log(
        'race delete failed: $error',
        name: 'RaceDeletion',
        level: 900,
      );
    }
    // Elmaradt törlés: a verseny visszajön a listába, nincs adatvesztés.
    state = {...state}..remove(raceId);
  }

  void _cancelTimers() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
  }
}
