import 'dart:math';

/// Időre súlyozott helyi másodfokú regresszió (LOESS) egy mért sor mentén
/// (ADR 0058 D7 2.).
///
/// A [positions] szigorúan növekvő helyek (a TWA-sorok foka), a [values] a
/// mért értékek (`null` = nem mért), a [weights] a mért idők. Minden hely,
/// amely a legelső és a legutolsó mért hely közé esik (a végpontokat is
/// beleértve), a környező mért pontokra illesztett másodfokú polinom
/// értékét kapja; a tartományon kívüli hely `null` marad.
///
/// A pont súlya a mért idő és a trikubikus távolság-súly szorzata:
/// `(1 − (d / bandwidth)³)³`, ahol `d` a pont távolsága; a [bandwidth]-nél
/// nem közelebbi pont nem számít. Ha a környezetben három pontnál kevesebb
/// van, az illesztés foka is kisebb (két pontnál egyenes, egynél az
/// értéke). Ha egy mért pont nélküli hely környezetében nincs mért pont
/// mindkét oldalon (a [bandwidth]-nél szélesebb lyuk, vagy a lyuk egyik
/// széle), az értéke a két legközelebbi kész érték közti lineáris
/// interpoláció: a polinom egy oldalról kivetítene.
///
/// Pure függvény; a három lista egyforma hosszú, a [bandwidth] pozitív.
List<double?> localQuadraticSmooth({
  required List<double> positions,
  required List<double?> values,
  required List<double> weights,
  required double bandwidth,
}) {
  if (positions.length != values.length || positions.length != weights.length) {
    throw ArgumentError('positions, values and weights differ in length');
  }
  if (!(bandwidth > 0)) {
    throw ArgumentError.value(bandwidth, 'bandwidth', 'must be positive');
  }
  final measured = [
    for (var index = 0; index < values.length; index++)
      if (values[index] case final double value when weights[index] > 0)
        (position: positions[index], value: value, weight: weights[index]),
  ];
  if (measured.isEmpty) return List<double?>.filled(values.length, null);
  final first = measured.first.position;
  final last = measured.last.position;
  final smoothed = [
    for (final position in positions)
      position < first || position > last
          ? null
          : _fitAt(position, measured, bandwidth),
  ];
  return _interpolateHoles(positions, smoothed);
}

typedef _Point = ({double position, double value, double weight});

// A [position] helyen az illesztett polinom értéke, vagy `null`, ha a
// környezetben nincs mért pont.
double? _fitAt(double position, List<_Point> measured, double bandwidth) {
  final local = <_Point>[];
  for (final point in measured) {
    final distance = (point.position - position).abs() / bandwidth;
    if (distance >= 1) continue;
    final tricube = pow(1 - pow(distance, 3), 3).toDouble();
    local.add((
      // A helyet a sávszélességre skálázzuk a jó kondícionáltságért.
      position: (point.position - position) / bandwidth,
      value: point.value,
      weight: point.weight * tricube,
    ));
  }
  // Mért pont nélküli helyen csak két oldalról körülvett környezetből
  // illesztünk: egy oldalról a polinom kivetítene, nem interpolálna.
  final hasOwnPoint = local.any((point) => point.position == 0);
  final hasBothSides =
      local.any((point) => point.position < 0) &&
      local.any((point) => point.position > 0);
  if (!hasOwnPoint && !hasBothSides) return null;
  for (var degree = min(2, local.length - 1); degree >= 0; degree--) {
    final intercept = _polynomialIntercept(local, degree);
    if (intercept != null) return intercept;
  }
  return null;
}

// A súlyozott legkisebb négyzetes polinom ([degree] fokú) értéke a 0 helyen
// (a konstans tag), vagy `null`, ha a normálegyenlet szinguláris.
double? _polynomialIntercept(List<_Point> points, int degree) {
  final size = degree + 1;
  final matrix = [
    for (var row = 0; row < size; row++) List<double>.filled(size + 1, 0),
  ];
  for (final point in points) {
    for (var row = 0; row < size; row++) {
      final rowPower = pow(point.position, row).toDouble();
      for (var column = 0; column < size; column++) {
        matrix[row][column] +=
            point.weight * rowPower * pow(point.position, column);
      }
      matrix[row][size] += point.weight * rowPower * point.value;
    }
  }
  return _solveFirst(matrix);
}

// Gauss-elimináció részleges főelem-választással a kibővített mátrixon; az
// első ismeretlen, vagy `null`, ha a mátrix (közel) szinguláris.
double? _solveFirst(List<List<double>> matrix) {
  final size = matrix.length;
  final threshold = _relativeSingularThreshold * _largestCoefficient(matrix);
  for (var pivot = 0; pivot < size; pivot++) {
    var best = pivot;
    for (var row = pivot + 1; row < size; row++) {
      if (matrix[row][pivot].abs() > matrix[best][pivot].abs()) best = row;
    }
    if (!(matrix[best][pivot].abs() > threshold)) return null;
    final swapped = matrix[pivot];
    matrix[pivot] = matrix[best];
    matrix[best] = swapped;
    for (var row = 0; row < size; row++) {
      if (row == pivot) continue;
      final factor = matrix[row][pivot] / matrix[pivot][pivot];
      for (var column = pivot; column <= size; column++) {
        matrix[row][column] -= factor * matrix[pivot][column];
      }
    }
  }
  return matrix[0][size] / matrix[0][0];
}

// A főelem a legnagyobb együtthatóhoz mérve ennél kisebb: a különbség csak
// kerekítési hiba, a normálegyenlet szinguláris (kevés különböző hely).
const double _relativeSingularThreshold = 1e-12;

double _largestCoefficient(List<List<double>> matrix) {
  var largest = 0.0;
  for (final row in matrix) {
    for (var column = 0; column < matrix.length; column++) {
      largest = max(largest, row[column].abs());
    }
  }
  return largest;
}

// A tartományon belüli lyukak lineáris kitöltése a két legközelebbi kész
// érték között. A tartomány két vége mindig kész (ott mért pont van).
List<double?> _interpolateHoles(List<double> positions, List<double?> values) {
  final filled = [...values];
  int? previous;
  for (var index = 0; index < values.length; index++) {
    if (values[index] == null) continue;
    if (previous != null && index - previous > 1) {
      _fillLinear(filled, positions, from: previous, to: index);
    }
    previous = index;
  }
  return filled;
}

void _fillLinear(
  List<double?> values,
  List<double> positions, {
  required int from,
  required int to,
}) {
  // A `!` biztonságos: a két végpont a hívó szerint kész érték.
  final start = values[from]!;
  final end = values[to]!;
  final span = positions[to] - positions[from];
  for (var index = from + 1; index < to; index++) {
    final fraction = (positions[index] - positions[from]) / span;
    values[index] = start + (end - start) * fraction;
  }
}
