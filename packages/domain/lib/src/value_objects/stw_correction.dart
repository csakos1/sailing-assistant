import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Egy dátumtól érvényes STW-szorzó (ADR 0049 D6, Addendum 3 T2).
///
/// A vízsebesség-mérő a 2026-os szezonban kb. 8%-kal alulmért; a szorzót
/// a felhasználó adja a szerver konfigjában. A konfig bemenetét a szerver
/// validálja, ide már csak érvényes érték jön.
@immutable
class StwCorrection extends Equatable {
  /// A [from] pillanattól érvényes [factor] szorzó.
  StwCorrection({required DateTime from, required this.factor})
    : from = from.toUtc(),
      assert(
        factor.isFinite && factor > 0,
        'A szorzó véges, pozitív szám.',
      );

  /// Az érvényesség kezdete (UTC), a határt is beleértve.
  final DateTime from;

  /// A szorzó, amellyel a mért STW-t szorozni kell.
  final double factor;

  @override
  List<Object?> get props => [from, factor];
}

/// A [stwMps] vízsebesség a [timestamp] pillanatban érvényes szorzóval.
///
/// A legkésőbbi olyan bejegyzés számít, amelynek `from`-ja nem későbbi a
/// [timestamp]-nél; a [corrections] sorrendje nem számít. Ha egyik sem
/// érvényes még, a mért érték marad.
double correctStw(
  double stwMps,
  DateTime timestamp,
  List<StwCorrection> corrections,
) {
  StwCorrection? latest;
  for (final correction in corrections) {
    if (correction.from.isAfter(timestamp)) continue;
    if (latest == null || correction.from.isAfter(latest.from)) {
      latest = correction;
    }
  }
  return latest == null ? stwMps : stwMps * latest.factor;
}
