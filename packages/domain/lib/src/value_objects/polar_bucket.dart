import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Egy 2 csomós szélvödör összegei egy futamon (ADR 0049 D9, D10).
@immutable
class PolarBucket extends Equatable {
  /// Vödör [seconds] mért másodperccel és a `% × másodperc` összegével.
  const PolarBucket({required this.seconds, required this.pctSecondsSum});

  /// A vödörbe eső mért másodpercek.
  final int seconds;

  /// A vödör `% × másodperc` szorzatainak összege.
  final double pctSecondsSum;

  /// A vödör %-átlaga; `null`, ha üres.
  double? get averagePct => seconds == 0 ? null : pctSecondsSum / seconds;

  /// A két vödör összege.
  PolarBucket operator +(PolarBucket other) => PolarBucket(
    seconds: seconds + other.seconds,
    pctSecondsSum: pctSecondsSum + other.pctSecondsSum,
  );

  @override
  List<Object?> get props => [seconds, pctSecondsSum];
}
