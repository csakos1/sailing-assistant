/// A megjelenítendő név (fiók, eszköz) leghosszabb alakja, Unicode
/// kódpontban.
const int maximumDisplayNameLength = 40;

/// A [raw] név a két végén levágva, vagy `null`, ha nem használható
/// (ADR 0051 D2, D3).
///
/// Üres, [maximumDisplayNameLength]-nél hosszabb, illetve vezérlőkaraktert,
/// sor- és bekezdés-elválasztót, irányvezérlőt vagy nulla szélességű
/// karaktert tartalmazó név nem fogadható el. Ez a név az aláírt
/// csatlakozási üzenet egyik sora, ezért sortörés nem lehet benne; a
/// tulajdonos ezt látja a jóváhagyáskor, ezért láthatatlan vagy
/// megfordító karakterrel sem álcázható.
String? normalizeDisplayName(String raw) {
  final name = raw.trim();
  if (name.isEmpty) return null;
  final runes = name.runes.toList();
  if (runes.length > maximumDisplayNameLength) return null;
  return runes.any(_isForbidden) ? null : name;
}

bool _isForbidden(int rune) =>
    rune < 0x20 ||
    (rune >= 0x7F && rune <= 0x9F) ||
    // Feltételes kötőjel, arab betűjelölő, mongol magánhangzó-elválasztó.
    rune == 0xAD ||
    rune == 0x61C ||
    rune == 0x180E ||
    // Nulla szélességű jelek és a bal-jobb jelölők.
    (rune >= 0x200B && rune <= 0x200F) ||
    // Sor- és bekezdés-elválasztó, irányvezérlők.
    (rune >= 0x2028 && rune <= 0x202E) ||
    // Szóköz-tiltó és izoláló irányvezérlők.
    (rune >= 0x2060 && rune <= 0x2069) ||
    rune == 0xFEFF ||
    // Címke-karakterek.
    (rune >= 0xE0000 && rune <= 0xE007F);
