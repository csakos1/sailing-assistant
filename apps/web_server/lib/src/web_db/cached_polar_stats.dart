import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';
import 'package:race_archive_api/race_archive_api.dart';

/// Egy verseny tárolt polár-teljesítménye (ADR 0049 D10, Addendum 4 U4,
/// U5).
///
/// A [window] az az ablak, amelyből készült, a [fingerprint] a polár és a
/// korrekció ujjlenyomata akkor. A frissességet a [stateFor] dönti el.
final class CachedPolarStats extends Equatable {
  /// Tárolt teljesítmény a [window] ablakból.
  CachedPolarStats({
    required this.window,
    required this.fingerprint,
    required this.performance,
    required DateTime computedAt,
  }) : computedAt = computedAt.toUtc();

  /// A számítás ablaka: hivatalos vagy rögzítés-ablak.
  final StatsWindow window;

  /// A polár és a korrekció ujjlenyomata a számításkor.
  final String fingerprint;

  /// A futam összegei és eloszlásai.
  final PolarPerformance performance;

  /// A számítás ideje (UTC).
  final DateTime computedAt;

  /// A sor állapota a [expectedWindow] várt ablakhoz és a mostani
  /// [currentFingerprint]-hez mérve.
  PolarCacheState stateFor(
    StatsWindow expectedWindow,
    String currentFingerprint,
  ) => window == expectedWindow && fingerprint == currentFingerprint
      ? PolarCacheState.fresh
      : PolarCacheState.stale;

  @override
  List<Object?> get props => [window, fingerprint, performance, computedAt];
}

/// A [cached] sor állapota; hiányzó sornál [PolarCacheState.missing].
PolarCacheState polarCacheStateOf(
  CachedPolarStats? cached,
  StatsWindow expectedWindow,
  String currentFingerprint,
) =>
    cached?.stateFor(expectedWindow, currentFingerprint) ??
    PolarCacheState.missing;
