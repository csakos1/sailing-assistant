// A feltöltött fájlok fejléc-ellenőrzése (ADR 0047 D6 + Addendum 2 B3).
// Pure függvények a fájl első bájtjain, hogy I/O nélkül tesztelhetők
// legyenek.

/// Ennyi bájt kell a [hasSqliteHeader]-nek.
const int sqliteHeaderLength = 16;

/// Ennyi bájt a WAL-fejléc; ennél rövidebb, nem üres fájl nem WAL.
const int walHeaderLength = 32;

// Az SQLite fő fájl magic stringje: "SQLite format 3" + NUL.
const List<int> _sqliteMagic = [
  0x53, 0x51, 0x4c, 0x69, 0x74, 0x65, 0x20, 0x66, //
  0x6f, 0x72, 0x6d, 0x61, 0x74, 0x20, 0x33, 0x00, //
];

/// Igaz, ha a [firstBytes] egy SQLite fő fájl fejlécével kezdődik.
bool hasSqliteHeader(List<int> firstBytes) {
  if (firstBytes.length < sqliteHeaderLength) return false;
  for (var i = 0; i < sqliteHeaderLength; i++) {
    if (firstBytes[i] != _sqliteMagic[i]) return false;
  }
  return true;
}

/// Egy feltöltött `-wal` fájl besorolása.
enum WalHeaderKind {
  /// 0 bájtos fájl: nincs benne keret, figyelmeztetés nélkül kihagyható.
  empty,

  /// Érvényes WAL-fejléc: a fő fájl mellé másolható.
  valid,

  /// Nem WAL (pl. egy `cat` hibaüzenete a lehúzásból): figyelmeztetéssel
  /// kihagyjuk.
  invalid,
}

/// A [firstBytes] (a fájl eleje) és a teljes [fileLength] alapján sorolja
/// be a WAL-fájlt.
///
/// A WAL magic big-endian `0x377f0682` vagy `0x377f0683`; a kettő csak a
/// checksum bájtsorrendjében különbözik.
WalHeaderKind classifyWalHeader(
  List<int> firstBytes, {
  required int fileLength,
}) {
  if (fileLength == 0) return WalHeaderKind.empty;
  if (fileLength < walHeaderLength || firstBytes.length < 4) {
    return WalHeaderKind.invalid;
  }
  final isWalMagic =
      firstBytes[0] == 0x37 &&
      firstBytes[1] == 0x7f &&
      firstBytes[2] == 0x06 &&
      (firstBytes[3] == 0x82 || firstBytes[3] == 0x83);
  return isWalMagic ? WalHeaderKind.valid : WalHeaderKind.invalid;
}
