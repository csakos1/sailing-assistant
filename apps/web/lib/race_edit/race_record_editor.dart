import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foretack_web/api/api_failure.dart';
import 'package:foretack_web/api/archive_api_client.dart';
import 'package:foretack_web/app/api_providers.dart';
import 'package:foretack_web/race_detail/race_detail_providers.dart';
import 'package:foretack_web/race_log/race_log_providers.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';

/// A szerkesztők írásai a szerverre (ADR 0048 Addendum 4 K16).
///
/// Alkalmazás-réteg: a klienst hívja, és siker után érvényteleníti a
/// napló és a részletező providerét, hogy a következő olvasás friss adatot
/// hozzon. A képernyő csak a navigációt és a snackbart intézi.
class RaceRecordEditor {
  /// Szerkesztő a [_ref] providerei fölött.
  RaceRecordEditor(this._ref);

  final Ref _ref;

  /// Egy telemetriás verseny eredményének mentése.
  Future<Result<RaceResult, ApiFailure>> saveResult(
    String raceId,
    RaceResultInput input,
  ) async {
    final result = await _client.saveRaceResult(raceId, input);
    if (result is Ok) _invalidate(raceId);
    return result;
  }

  /// Új kézi verseny; a válasz az új verseny napló-sora.
  Future<Result<RaceSummary, ApiFailure>> createManualRace(
    ManualRaceRequest request,
  ) async {
    final result = await _client.createManualRace(request);
    if (result is Ok) _ref.invalidate(raceSummariesProvider);
    return result;
  }

  /// Egy kézi verseny mentése; a válasz a frissített napló-sor.
  Future<Result<RaceSummary, ApiFailure>> updateManualRace(
    String raceId,
    ManualRaceRequest request,
  ) async {
    final result = await _client.updateManualRace(raceId, request);
    if (result is Ok) _invalidate(raceId);
    return result;
  }

  /// Egy kézi verseny törlése.
  ///
  /// Ha a szerver szerint a verseny már nincs meg (`RaceNotFound`), az is
  /// siker: a felhasználó célja, hogy ne legyen ott (K15). Csak a napló
  /// frissül: a törölt verseny részletezője épp bezárul, és egy újratöltés
  /// csak egy fölösleges 404-et hozna.
  Future<Result<void, ApiFailure>> deleteManualRace(String raceId) async {
    final result = await _client.deleteManualRace(raceId);
    final isGone = switch (result) {
      Ok() => true,
      Err(error: ServerFailure(error: RaceNotFound())) => true,
      Err() => false,
    };
    if (!isGone) return result;
    _ref.invalidate(raceSummariesProvider);
    return const Ok(null);
  }

  ArchiveApiClient get _client => _ref.read(archiveApiClientProvider);

  void _invalidate(String raceId) => _ref
    ..invalidate(raceSummariesProvider)
    ..invalidate(raceDetailProvider(raceId));
}

/// A [RaceRecordEditor] példánya; a tesztek az `archiveApiClientProvider`
/// felülírásával cserélik a hálózatot alatta.
final Provider<RaceRecordEditor> raceRecordEditorProvider =
    Provider<RaceRecordEditor>(RaceRecordEditor.new);
