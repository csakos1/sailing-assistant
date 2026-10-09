import 'package:web/web.dart' as web;

/// Letöltés a [href] címről egy rejtett `<a download>` kattintásával
/// (ADR 0050 Addendum 3 G2).
///
/// Azonos origó, így a böngésző a Caddy `basic_auth` hitelesítését viszi,
/// és a fájlnevet a szerver `Content-Disposition` fejléce adja. A
/// folyamatot és a hibát a böngésző letöltés-sávja mutatja; az oldal a
/// státuszt nem látja.
void startFileDownload(String href) {
  final anchor = web.HTMLAnchorElement()
    ..href = href
    ..download = ''
    ..style.display = 'none';
  web.document.body?.appendChild(anchor);
  anchor
    ..click()
    ..remove();
}
