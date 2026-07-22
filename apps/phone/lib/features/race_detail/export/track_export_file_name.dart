/// A magyar ékezetek ASCII-megfelelői a fájlnév-slughoz.
///
/// Szándékosan szűk lista: a versenynevek magyarul íródnak, és egy általános
/// Unicode-normalizálás behúzna egy csomagot azért, hogy kilenc karaktert
/// kezeljen. Ami nem szerepel itt, az kötőjellé válik.
const Map<String, String> _accentFolding = {
  'á': 'a',
  'é': 'e',
  'í': 'i',
  'ó': 'o',
  'ö': 'o',
  'ő': 'o',
  'ú': 'u',
  'ü': 'u',
  'ű': 'u',
};

/// A slug maximális hossza — a fájlnév maradjon olvasható a share sheeten.
const int _maxSlugLength = 40;

/// A megosztott PNG fájlneve: `foretack-<ISO-dátum>-<verseny-slug>.png`.
///
/// A dátum ISO-alakban megy, nem a fejléc magyar formátumában: a fájlnevek
/// így rendezhetők, és nem tartalmaznak ékezetet vagy szóközt. Hiányzó
/// startdátumnál a dátum-tag egyszerűen kimarad, ahogy az üres slug is.
String trackExportFileName({
  required String raceName,
  required DateTime? startedAt,
}) {
  final parts = <String>['foretack'];
  if (startedAt != null) {
    parts.add(_isoDate(startedAt));
  }
  final slug = _slugify(raceName);
  if (slug.isNotEmpty) {
    parts.add(slug);
  }
  return '${parts.join('-')}.png';
}

/// `2026-07-18` alak, helyi idő szerint (a verseny helyi napja számít).
String _isoDate(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}

/// Kisbetűs, ékezet nélküli, kötőjelezett alak a versenynévből.
String _slugify(String raceName) {
  final folded = StringBuffer();
  for (final character in raceName.toLowerCase().split('')) {
    folded.write(_accentFolding[character] ?? character);
  }

  final slug = folded
      .toString()
      .replaceAll(RegExp('[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  if (slug.length <= _maxSlugLength) {
    return slug;
  }
  // A csonkolás a kötőjel közepén is elvághat, ezért utólag még tisztítunk.
  return slug.substring(0, _maxSlugLength).replaceAll(RegExp(r'-+$'), '');
}
