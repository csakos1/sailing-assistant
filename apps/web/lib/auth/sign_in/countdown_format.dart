/// A visszaszámláló szövege (17a, 17d-1): `0:42`, `9:36`.
///
/// Negatív értéket nem mutat: a lejáratot a szerver mondja meg, addig a
/// kijelzés `0:00`-n áll.
String formatCountdown(int seconds) {
  final shown = seconds < 0 ? 0 : seconds;
  final remainder = (shown % 60).toString().padLeft(2, '0');
  return '${shown ~/ 60}:$remainder';
}
