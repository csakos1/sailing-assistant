/// Egy CSV-sor mezői (RFC 4180): a mező idézőjeles is lehet, benne a
/// vessző és a kettőzött idézőjel (`""`) megengedett. Hibás idézésnél
/// `null`.
///
/// A DB-IP csak a szóközös vagy különleges karakteres mezőket teszi
/// idézőjelbe (`"South Brisbane"`, de `Wenquan`), ezért a sima `split`
/// nem elég (Addendum 6 N8).
List<String>? parseCsvLine(String line) {
  final fields = <String>[];
  final field = StringBuffer();
  var index = 0;
  while (true) {
    field.clear();
    if (index < line.length && line[index] == '"') {
      final end = _readQuoted(line, index + 1, field);
      if (end == null) return null;
      index = end;
    } else {
      while (index < line.length && line[index] != ',') {
        if (line[index] == '"') return null;
        field.write(line[index]);
        index++;
      }
    }
    fields.add(field.toString());
    if (index == line.length) return fields;
    if (line[index] != ',') return null;
    index++;
  }
}

// Egy idézőjeles mező a [start] utáni karaktertől; a záró idézőjel utáni
// index, vagy `null`, ha nincs lezárva.
int? _readQuoted(String line, int start, StringBuffer field) {
  var index = start;
  while (index < line.length) {
    final character = line[index];
    if (character != '"') {
      field.write(character);
      index++;
    } else if (index + 1 < line.length && line[index + 1] == '"') {
      field.write('"');
      index += 2;
    } else {
      return index + 1;
    }
  }
  return null;
}
