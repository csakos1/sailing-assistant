import 'package:race_archive_api/race_archive_api.dart';
import 'package:uuid/uuid.dart';
import 'package:web_server/src/race/race_summaries.dart';
import 'package:web_server/src/web_db/manual_race_repository.dart';
import 'package:web_server/src/web_db/race_result_repository.dart';
import 'package:web_server/src/web_db/transaction_runner.dart';

/// A kézi versenyek létrehozása, mentése és törlése (ADR 0048 D2, D6 +
/// Addendum 3 I7).
///
/// Az alapadatok és az eredmény egy tranzakcióban íródnak, mert a
/// szerkesztő egy képernyő: félig mentett kézi verseny nem maradhat. Az
/// archívumot és a statisztika-cache-t nem érinti, ezért nem zárol (I5).
class ManualRaceService {
  /// Szolgáltatás a webes tárakkal; az azonosítót a [newId], az időt a
  /// [now] adja.
  ManualRaceService({
    required ManualRaceRepository manualRaces,
    required RaceResultRepository results,
    required TransactionRunner runInTransaction,
    String Function() newId = _uuidV4,
    DateTime Function() now = DateTime.now,
  }) : _manualRaces = manualRaces,
       _results = results,
       _runInTransaction = runInTransaction,
       _newId = newId,
       _now = now;

  final ManualRaceRepository _manualRaces;
  final RaceResultRepository _results;
  final TransactionRunner _runInTransaction;
  final String Function() _newId;
  final DateTime Function() _now;

  /// Igaz, ha az [id] egy létező kézi verseny.
  Future<bool> exists(String id) async => await _manualRaces.get(id) != null;

  /// Új kézi verseny a validált [request]-ből; a napló-sora.
  Future<RaceSummary> create(ManualRaceRequest request) =>
      _runInTransaction(() async {
        final now = _now().toUtc();
        final record = await _manualRaces.insert(
          _newId(),
          request.race,
          now: now,
        );
        final result = await _saveResult(record.id, request.result, now);
        return manualSummaryOf(record, result);
      });

  /// Az [id] kézi verseny mentése a validált [request]-ből; `null`, ha
  /// nincs ilyen kézi verseny.
  Future<RaceSummary?> update(String id, ManualRaceRequest request) =>
      _runInTransaction(() async {
        final now = _now().toUtc();
        final record = await _manualRaces.update(id, request.race, now: now);
        if (record == null) return null;
        final result = await _saveResult(id, request.result, now);
        return manualSummaryOf(record, result);
      });

  /// Az [id] kézi verseny törlése az eredményével együtt; igaz, ha volt
  /// ilyen.
  Future<bool> delete(String id) => _runInTransaction(() async {
    final isDeleted = await _manualRaces.delete(id);
    if (isDeleted) await _results.delete(id);
    return isDeleted;
  });

  // Csupa üres eredmény: a korábbi sor törlődik, eredmény nincs (D3).
  Future<RaceResult?> _saveResult(
    String raceId,
    RaceResultInput content,
    DateTime now,
  ) async {
    if (content.isEmpty) {
      await _results.delete(raceId);
      return null;
    }
    return _results.upsert(raceId, content, updatedAt: now);
  }
}

String _uuidV4() => const Uuid().v4();
