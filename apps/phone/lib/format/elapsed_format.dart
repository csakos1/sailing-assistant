/// Egy eltelt idő „ÓÓ:PP:MM" alakban (pl. „00:42:10").
///
/// Az óra nem csordul át a napon: egy kétnapos Kékszalag „30:12:05".
/// Negatív időtartamot (óraeltérés a rajt és a telefon órája között)
/// nullának ír, nem mínusz jellel.
String formatElapsed(Duration elapsed) {
  final seconds = elapsed.isNegative ? 0 : elapsed.inSeconds;
  final hours = seconds ~/ 3600;
  final minutes = (seconds ~/ 60) % 60;
  final rest = seconds % 60;
  return '${hours.toString().padLeft(2, '0')}:'
      '${minutes.toString().padLeft(2, '0')}:'
      '${rest.toString().padLeft(2, '0')}';
}
