/// Egy TWA-sor hézagainak kitöltése a TWS mentén (ADR 0058 D7 4., D5).
///
/// A [knots] a szigorúan növekvő TWS-oszlopok, a [values] a sor kész
/// értékei (`null` = hézag). A két kész érték közti hézag lineárisan
/// interpolálódik a szélsebesség szerint; a legfelső kész oszlop fölött az
/// értéke megmarad; a legalsó kész oszlop alatt a cél a 0 csomós horgony
/// felé arányos (`érték × tws / tws_legalsó`), ugyanúgy, ahogy a lookup a
/// tengely alatt számol (D5). A kész érték nem változik; a csupa `null` sor
/// csupa `null` marad.
///
/// Pure függvény; a két lista egyforma hosszú, a [knots] pozitív.
List<double?> fillAlongTws(List<double?> values, List<double> knots) {
  if (values.length != knots.length) {
    throw ArgumentError('values and knots differ in length');
  }
  final known = [
    for (var index = 0; index < values.length; index++)
      if (values[index] != null) index,
  ];
  if (known.isEmpty) return [...values];
  final filled = [...values];
  // A `!` biztonságos: a `known` indexein az érték nem `null`.
  final lowest = known.first;
  final lowestValue = values[lowest]!;
  for (var index = 0; index < lowest; index++) {
    filled[index] = lowestValue * knots[index] / knots[lowest];
  }
  final highestValue = values[known.last]!;
  for (var index = known.last + 1; index < values.length; index++) {
    filled[index] = highestValue;
  }
  for (var gap = 1; gap < known.length; gap++) {
    final from = known[gap - 1];
    final to = known[gap];
    final start = values[from]!;
    final end = values[to]!;
    for (var index = from + 1; index < to; index++) {
      final fraction = (knots[index] - knots[from]) / (knots[to] - knots[from]);
      filled[index] = start + (end - start) * fraction;
    }
  }
  return filled;
}
