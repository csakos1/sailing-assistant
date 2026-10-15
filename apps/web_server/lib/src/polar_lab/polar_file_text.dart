import 'package:web_server/src/polar_lab/polar_build_axes.dart';
import 'package:web_server/src/polar_lab/smoothed_polar_grid.dart';

/// A kész rács `.pol` szövege (ADR 0028 Addendum 1 A5, ADR 0058 D4, D8).
///
/// A fejléc `TWA/TWS;<oszlopok>` (a beépített polárral egyezően; a parser
/// a kis- és nagybetűt nem különbözteti meg), utána soronként
/// `<TWA>;<cellák>` 0-tól 180°-ig. A cella két tizedes, ponttal; az üres
/// cella `0.00`. A sorvég `\n`, a fájl sorvéggel zárul.
String polarFileText(SmoothedPolarGrid grid) {
  final buffer = StringBuffer()
    ..writeln(
      [
        'TWA/TWS',
        for (final knots in grid.axes.twsColumnsKnots) _axisLabel(knots),
      ].join(';'),
    );
  for (final (row, values) in grid.rows.indexed) {
    buffer.writeln(
      [
        PolarBuildAxes.twaDegreesOfRow(row),
        for (final value in values) (value ?? 0).toStringAsFixed(2),
      ].join(';'),
    );
  }
  return buffer.toString();
}

// Az egész csomó tizedes nélkül (`10`), a tört ponttal (`2.5`).
String _axisLabel(double knots) =>
    knots == knots.roundToDouble() ? knots.round().toString() : '$knots';
