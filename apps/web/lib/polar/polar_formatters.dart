// A polár-táblázat szövegei (ADR 0049 Addendum 5). Pure függvények,
// magyar tizedesvesszővel.

/// Egy százalék egy tizedesre, jel nélkül: `87,2`.
String formatPolarPct(double pct) => _oneDecimal(pct);

/// Egy 0–1 közötti arány százalékban, egy tizedesre: `39,0`.
String formatPolarShare(double share) => _oneDecimal(share * 100);

/// Egy időtartam órában és percben: `2 ó 53 p`; óra alatt `48 p`.
String formatHoursMinutes(Duration duration) {
  final hours = duration.inHours;
  final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
  return hours == 0 ? '${duration.inMinutes} p' : '$hours ó $minutes p';
}

/// Egy másodpercben mért idő órában, egy tizedesre: `58,3`.
String formatMeasuredHours(int seconds) => _oneDecimal(seconds / 3600);

String _oneDecimal(double value) =>
    value.toStringAsFixed(1).replaceAll('.', ',');
