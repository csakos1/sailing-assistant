import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foretack_web/app/api_providers.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';

/// Egy verseny részletezője a szerverről (ADR 0048 D6 + Addendum 4 K7).
///
/// `autoDispose`: a képernyő bezárásakor eldobódik, így egy újranyitás
/// friss adatot tölt (a szerkesztő mentése után is, S7c). A hiba az
/// `ApiFailure`, dobva, mint a napló providerénél.
final AutoDisposeFutureProviderFamily<RaceDetail, String> raceDetailProvider =
    FutureProvider.autoDispose.family<RaceDetail, String>((ref, raceId) async {
      final result = await ref
          .watch(archiveApiClientProvider)
          .fetchRaceDetail(raceId);
      return switch (result) {
        Ok(:final value) => value,
        Err(:final error) => throw error,
      };
    });
