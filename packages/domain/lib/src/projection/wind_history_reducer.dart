import 'package:domain/src/entities/wind_observation.dart';

/// A TWD-observation történetet karbantartó pure reducer
/// (ADR 0017 D2, ARCHITECTURE.md 8.6).
///
/// Korábban az `apps/phone` `windHistoryProvider`-ének `_appended`
/// metódusa volt; a háttér-`RaceEngine` (ADR 0017) Riverpod nélkül is
/// használja, ezért a domainbe került. A [call] tiszta: új listát ad,
/// nem mutál in-place.
///
/// A puffer **idő-nyírt**: a legfrissebb observation időbélyegéhez
/// képest a `window`-nál (default 30 perc) régebbieket levágja. A 30
/// perc bőven a `CalculateWindShiftTrend` (default 10 perces) ablaka
/// fölött van, hogy a runtime window-váltás (5f) ne ürítse a történetet.
class WindHistoryReducer {
  /// Konstans reducer — nincs állapota.
  const WindHistoryReducer();

  /// Hozzáfűzi az `observation`-t a `history`-hoz, majd a legfrissebb
  /// observationhöz képest a `window`-nál régebbieket levágja. Új lista
  /// (immutable), a cutoff szigorú (`isAfter`).
  List<WindObservation> call(
    List<WindObservation> history,
    WindObservation observation, {
    Duration window = const Duration(minutes: 30),
  }) {
    final next = [...history, observation];
    final cutoff = observation.timestamp.subtract(window);
    return next.where((o) => o.timestamp.isAfter(cutoff)).toList();
  }
}
