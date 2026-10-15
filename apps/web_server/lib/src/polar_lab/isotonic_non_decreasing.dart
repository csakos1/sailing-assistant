/// Súlyozott izotonikus (nem csökkenő) regresszió (ADR 0058 D7 3.).
///
/// A [values] kész értékeire (a `null` kimarad, és `null` marad) a
/// legkisebb súlyozott négyzetes eltérésű nem csökkenő sorozatot adja: ahol
/// egy érték a következőnél nagyobb, a kettő (és szükség szerint a
/// szomszédaik) a [weights] szerinti súlyozott átlagukra áll. Ez a
/// „pool adjacent violators" (PAVA) algoritmus. A már nem csökkenő sorozat
/// változatlan.
///
/// Pure függvény; a két lista egyforma hosszú, a súlyok pozitívak.
List<double?> isotonicNonDecreasing(
  List<double?> values,
  List<double> weights,
) {
  if (values.length != weights.length) {
    throw ArgumentError('values and weights differ in length');
  }
  final blocks = <_Block>[];
  for (var index = 0; index < values.length; index++) {
    final value = values[index];
    if (value == null) continue;
    final weight = weights[index];
    if (!(weight > 0)) {
      throw ArgumentError.value(weight, 'weights[$index]', 'must be positive');
    }
    var block = _Block(weightedSum: value * weight, weight: weight, count: 1);
    while (blocks.isNotEmpty && blocks.last.mean > block.mean) {
      block = blocks.removeLast().merge(block);
    }
    blocks.add(block);
  }
  final fitted = [
    for (final block in blocks) ...List.filled(block.count, block.mean),
  ];
  var next = 0;
  return [for (final value in values) value == null ? null : fitted[next++]];
}

// Egymás melletti kész értékek összevont csoportja.
final class _Block {
  const _Block({
    required this.weightedSum,
    required this.weight,
    required this.count,
  });

  final double weightedSum;
  final double weight;
  final int count;

  double get mean => weightedSum / weight;

  _Block merge(_Block other) => _Block(
    weightedSum: weightedSum + other.weightedSum,
    weight: weight + other.weight,
    count: count + other.count,
  );
}
