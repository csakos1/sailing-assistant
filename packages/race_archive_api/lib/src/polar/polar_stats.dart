import 'package:equatable/equatable.dart';

/// Egy verseny vagy egy összesítő sor polár-mutatói (ADR 0049 D8, D11,
/// Addendum 4 U7).
///
/// A százalékok a korrigált STW és a polár cél-STW-jének hányadosai,
/// százszorosan; az arányok 0 és 1 közé esnek. Csak 60 mért másodperctől
/// létezik; kevesebb adatnál a sor `PolarStats` nélkül áll.
final class PolarStats extends Equatable {
  /// Mutatók a megadott értékekkel.
  const PolarStats({
    required this.measuredSeconds,
    required this.avgPct,
    required this.medianPct,
    required this.p90Pct,
    required this.p99Pct,
    required this.shareAtLeast90,
    required this.shareAtLeast100,
    this.avgTwsMps,
    this.bestFivePct,
  });

  /// A polár-minták másodperceinek összege.
  final int measuredSeconds;

  /// A polár-minták TWS-átlaga m/s-ben; a futamok átlaga sorban `null`.
  final double? avgTwsMps;

  /// A %-ok átlaga.
  final double avgPct;

  /// A %-eloszlás mediánja.
  final double medianPct;

  /// A %-eloszlás 90. percentilise.
  final double p90Pct;

  /// A %-eloszlás 99. percentilise.
  final double p99Pct;

  /// Öt egymást követő másodperc %-átlagának maximuma; a régi, 10 mp-es
  /// mintákból nem számolható.
  final double? bestFivePct;

  /// A legalább 90%-os másodpercek aránya (0–1).
  final double shareAtLeast90;

  /// A legalább 100%-os másodpercek aránya (0–1).
  final double shareAtLeast100;

  @override
  List<Object?> get props => [
    measuredSeconds,
    avgTwsMps,
    avgPct,
    medianPct,
    p90Pct,
    p99Pct,
    bestFivePct,
    shareAtLeast90,
    shareAtLeast100,
  ];
}
