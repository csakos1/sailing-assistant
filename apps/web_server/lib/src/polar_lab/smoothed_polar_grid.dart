import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:web_server/src/polar_lab/fill_along_tws.dart';
import 'package:web_server/src/polar_lab/isotonic_non_decreasing.dart';
import 'package:web_server/src/polar_lab/local_quadratic_smooth.dart';
import 'package:web_server/src/polar_lab/polar_build_axes.dart';
import 'package:web_server/src/polar_lab/raw_polar_grid.dart';

/// Honnan jön a kész polár egy cellájának értéke.
enum PolarCellOrigin {
  /// Mért cella: a nyers p90 simítva.
  measured,

  /// A TWA menti simítás töltötte (a mért sorok közti lyuk).
  smoothedAlongTwa,

  /// A TWS menti hézagtöltés adta (interpoláció, tartás vagy horgony).
  filledAlongTws,

  /// Nincs értéke: no-go sor, vagy a sorban sehol nincs adat.
  empty,
}

/// A simítás paraméterei (ADR 0058 D7); a kiinduló értékek az ADR-éi.
@immutable
final class PolarSmoothingParameters extends Equatable {
  /// Paraméterek az ADR kiinduló értékeivel, vagy a megadottakkal.
  const PolarSmoothingParameters({
    this.minimumMeasuredSeconds = 120,
    this.twaBandwidthDegrees = 15,
  });

  /// Ennyi mért idő alatt a cella nem számít mért értéknek (másodperc).
  final int minimumMeasuredSeconds;

  /// A TWA menti simítás sávszélessége fokban (±).
  final double twaBandwidthDegrees;

  @override
  List<Object?> get props => [minimumMeasuredSeconds, twaBandwidthDegrees];
}

/// A kész, simított polár-rács (ADR 0058 D7 1–4.).
///
/// 1. A [RawPolarGrid] mért cellái (legalább
///    [PolarSmoothingParameters.minimumMeasuredSeconds]).
/// 2. Oszloponként a TWA mentén helyi másodfokú regresszió
///    (`localQuadraticSmooth`) a mért sorok tartományán belül.
/// 3. Soronként a TWS mentén súlyozott izotonikus regresszió
///    (`isotonicNonDecreasing`); a súly a cella mért ideje, a simítással
///    töltött cellánál a mért cella legkisebb ideje.
/// 4. Soronként a hézagok a TWS mentén (`fillAlongTws`).
///
/// A no-go sorok ([PolarBuildAxes.firstSailingTwaRow] alatt) üresek.
@immutable
final class SmoothedPolarGrid {
  /// A kész rács a [raw] rácsból a [parameters] szerint.
  factory SmoothedPolarGrid.of(
    RawPolarGrid raw, {
    PolarSmoothingParameters parameters = const PolarSmoothingParameters(),
  }) {
    final alongTwa = _smoothColumnsAlongTwa(raw, parameters);
    final values = <List<double?>>[];
    final origins = <List<PolarCellOrigin>>[];
    for (var row = 0; row < PolarBuildAxes.twaRowCount; row++) {
      final rowValues = row < PolarBuildAxes.firstSailingTwaRow
          ? alongTwa[row]
          : _monotoneAndFilled(raw, parameters, row, alongTwa[row]);
      values.add(List.unmodifiable(rowValues));
      origins.add(
        List.unmodifiable([
          for (var column = 0; column < rowValues.length; column++)
            _originOf(
              isMeasured: _isMeasured(raw.cellAt(row, column), parameters),
              smoothedValue: alongTwa[row][column],
              finalValue: rowValues[column],
            ),
        ]),
      );
    }
    return SmoothedPolarGrid._(
      axes: raw.axes,
      values: List.unmodifiable(values),
      origins: List.unmodifiable(origins),
    );
  }

  const SmoothedPolarGrid._({
    required this.axes,
    required List<List<double?>> values,
    required List<List<PolarCellOrigin>> origins,
  }) : _values = values,
       _origins = origins;

  /// A rács tengelyei.
  final PolarBuildAxes axes;

  final List<List<double?>> _values;
  final List<List<PolarCellOrigin>> _origins;

  /// A rács sorai (TWA 0–180°), soronként a TWS-oszlopok értékei csomóban;
  /// `null` = üres cella.
  List<List<double?>> get rows => _values;

  /// A [row] és a [column] cella értéke csomóban, vagy `null`.
  double? valueAt(int row, int column) => _values[row][column];

  /// A [row] és a [column] cella értékének eredete.
  PolarCellOrigin originAt(int row, int column) => _origins[row][column];
}

bool _isMeasured(RawPolarCell? cell, PolarSmoothingParameters parameters) =>
    cell != null && cell.seconds >= parameters.minimumMeasuredSeconds;

// 1–2. lépés: oszloponként a mért cellák simítása a TWA mentén. A no-go
// sorok üresek maradnak.
List<List<double?>> _smoothColumnsAlongTwa(
  RawPolarGrid raw,
  PolarSmoothingParameters parameters,
) {
  const first = PolarBuildAxes.firstSailingTwaRow;
  final columnCount = raw.axes.twsColumnsKnots.length;
  final grid = [
    for (var row = 0; row < PolarBuildAxes.twaRowCount; row++)
      List<double?>.filled(columnCount, null),
  ];
  final positions = [
    for (var row = first; row < PolarBuildAxes.twaRowCount; row++)
      PolarBuildAxes.twaDegreesOfRow(row).toDouble(),
  ];
  for (var column = 0; column < columnCount; column++) {
    final cells = [
      for (var row = first; row < PolarBuildAxes.twaRowCount; row++)
        raw.cellAt(row, column),
    ];
    final smoothed = localQuadraticSmooth(
      positions: positions,
      values: [
        for (final cell in cells)
          _isMeasured(cell, parameters) ? cell?.p90Knots : null,
      ],
      weights: [for (final cell in cells) (cell?.seconds ?? 0).toDouble()],
      bandwidth: parameters.twaBandwidthDegrees,
    );
    for (final (index, value) in smoothed.indexed) {
      grid[first + index][column] = value;
    }
  }
  return grid;
}

// 3–4. lépés: egy sor izotonikus simítása és hézagtöltése a TWS mentén.
List<double?> _monotoneAndFilled(
  RawPolarGrid raw,
  PolarSmoothingParameters parameters,
  int row,
  List<double?> alongTwa,
) {
  final weights = [
    for (var column = 0; column < alongTwa.length; column++)
      max(
        raw.cellAt(row, column)?.seconds ?? 0,
        parameters.minimumMeasuredSeconds,
      ).toDouble(),
  ];
  return fillAlongTws(
    isotonicNonDecreasing(alongTwa, weights),
    raw.axes.twsColumnsKnots,
  );
}

PolarCellOrigin _originOf({
  required bool isMeasured,
  required double? smoothedValue,
  required double? finalValue,
}) {
  if (finalValue == null) return PolarCellOrigin.empty;
  if (isMeasured) return PolarCellOrigin.measured;
  if (smoothedValue != null) return PolarCellOrigin.smoothedAlongTwa;
  return PolarCellOrigin.filledAlongTws;
}
