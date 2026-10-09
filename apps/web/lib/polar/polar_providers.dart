import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foretack_web/api/api_failure.dart';
import 'package:foretack_web/app/api_providers.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';

/// Egy szezon polár-táblázata (ADR 0049 D14, Addendum 5 W1).
///
/// `autoDispose`: egy évváltás vagy újranyitás friss adatot tölt, így a
/// szerver háttér-frissítése után a régi értékek eltűnnek. A hiba az
/// `ApiFailure`, dobva; a szakasz a `PolarUnavailable`-t külön mondja.
final AutoDisposeFutureProviderFamily<SeasonPolarTable, int>
seasonPolarProvider = FutureProvider.autoDispose.family<SeasonPolarTable, int>(
  (ref, year) async {
    final result = await ref
        .watch(archiveApiClientProvider)
        .fetchSeasonPolar(year);
    return switch (result) {
      Ok(:final value) => value,
      Err(:final error) => throw error,
    };
  },
);

/// A szezonok időre súlyozott polár-sorai az „Összes év" nézethez.
final AutoDisposeFutureProvider<List<SeasonPolarSummary>> polarSeasonsProvider =
    FutureProvider.autoDispose<List<SeasonPolarSummary>>(
      (ref) async {
        final result = await ref
            .watch(archiveApiClientProvider)
            .fetchPolarSeasons();
        return switch (result) {
          Ok(:final value) => value,
          Err(:final error) => throw error,
        };
      },
    );

/// Egy verseny polár-blokkja a részletezőhöz; `null`, ha a blokk elmarad
/// (Addendum 5 W1): polár-forrás nélküli verseny vagy nem elérhető polár.
/// Más hibát dob, és a blokk akkor is elmarad.
final AutoDisposeFutureProviderFamily<RacePolarDetail?, String>
racePolarProvider = FutureProvider.autoDispose.family<RacePolarDetail?, String>(
  (ref, raceId) async {
    final result = await ref
        .watch(archiveApiClientProvider)
        .fetchRacePolar(raceId);
    return switch (result) {
      Ok(:final value) => value,
      Err(:final error) when _hidesBlock(error) => null,
      Err(:final error) => throw error,
    };
  },
);

bool _hidesBlock(ApiFailure failure) => switch (failure) {
  ServerFailure(error: RaceNotFound() || PolarUnavailable()) => true,
  _ => false,
};

/// Igaz, ha a [error] a szerver „nincs polár" válasza (ADR 0049 D5).
bool isPolarUnavailable(Object error) =>
    error is ServerFailure && error.error is PolarUnavailable;
