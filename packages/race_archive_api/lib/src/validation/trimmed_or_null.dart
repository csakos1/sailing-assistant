/// A [text] széleiről levágott változata, vagy `null`, ha így üres.
///
/// Az opcionális szövegmezők közös normalizálása: a csak szóközökből álló
/// díj vagy összefoglaló nem rögzített adat, nem üres szöveg.
String? trimmedOrNull(String? text) {
  final trimmed = text?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
