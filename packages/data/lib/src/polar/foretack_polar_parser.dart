import 'dart:convert';

import 'package:domain/domain.dart';
import 'package:shared/shared.dart';

/// A `.pol`-dialektus fejléc-prefixe (ADR 0028 Addendum 1 A5).
const _headerPrefix = 'twa/tws';

/// A `foretack.pol` (ADR 0028 Addendum 1 A5) tartalmát [Polar]-rá
/// parse-olja. Pure, determinista: nincs IO, nincs platform-függés, így
/// a `data` Flutter-csomagban is sima unit-teszttel fedett.
///
/// **Dialektus.** `;`-elválasztott szövegfájl. Az első nem-üres sor a
/// fejléc: `twa/tws;<TWS1>;<TWS2>;…` — a TWS-tengelyt adja csomóban. A
/// többi nem-üres sor egy-egy TWA-sor: `<TWA>;<cella1>;<cella2>;…`, az
/// első mező a TWA fokban, a többi a cél-STW csomóban. Az üres vödör
/// sentinelje `0.00` (vagy üres cella) — ezt a parser a [Polar]-rács
/// `null`-jára fordítja (a domain a hiányt `null`-lal jelzi, NEM 0.0).
///
/// **Untrusted bemenet.** A fájl kézzel/külső eszközzel készül, ezért a
/// hibát [Result]-tal jelezzük ([Err] [PolarLoadError]-ral), nem
/// assert-crashsel. A parser szándékosan szigorúbb a [Polar]
/// assertjeinél: a tengely-monotonitást és a TWA-tartományt itt
/// ellenőrizzük, hogy a [Polar] konstruktora valós bemeneten sose
/// dobjon.
Result<Polar, PolarLoadError> parseForetackPolar(String content) {
  final lines = const LineSplitter().convert(content);
  if (!lines.any((line) => line.trim().isNotEmpty)) {
    return const Err(PolarEmpty());
  }

  // A fejléc az első nem-üres sor; megjegyezzük az indexét, hogy az
  // adatsorokat utána kezdjük olvasni.
  var headerIndex = 0;
  while (headerIndex < lines.length && lines[headerIndex].trim().isEmpty) {
    headerIndex++;
  }

  final List<double> twsAxis;
  switch (_parseHeader(lines[headerIndex])) {
    case Ok(value: final axis):
      twsAxis = axis;
    case Err(error: final error):
      return Err(error);
  }

  final twaAxis = <double>[];
  final grid = <List<double?>>[];
  for (var i = headerIndex + 1; i < lines.length; i++) {
    final line = lines[i];
    if (line.trim().isEmpty) continue;

    final row = _parseDataRow(
      line: line,
      lineNumber: i + 1,
      twsCount: twsAxis.length,
      previousTwa: twaAxis.isEmpty ? null : twaAxis.last,
    );
    switch (row) {
      case Ok(value: final parsed):
        twaAxis.add(parsed.twa);
        grid.add(parsed.cells);
      case Err(error: final error):
        return Err(error);
    }
  }

  // Csak fejléc, vagy minden cella üres → a polár használhatatlan.
  if (twaAxis.isEmpty || !grid.any((row) => row.any((c) => c != null))) {
    return const Err(PolarNoUsableCells());
  }

  return Ok(Polar(twaAxis: twaAxis, twsAxis: twsAxis, grid: grid));
}

/// A fejlécsort TWS-tengellyé alakítja, vagy [PolarMalformedHeader]-t ad.
Result<List<double>, PolarLoadError> _parseHeader(String line) {
  final fields = line.split(';');
  if (fields.first.trim().toLowerCase() != _headerPrefix) {
    return const Err(PolarMalformedHeader());
  }

  final twsAxis = <double>[];
  for (final field in fields.skip(1)) {
    final value = double.tryParse(field.trim());
    if (value == null) return const Err(PolarMalformedHeader());
    twsAxis.add(value);
  }
  if (twsAxis.isEmpty || !_isStrictlyAscending(twsAxis)) {
    return const Err(PolarMalformedHeader());
  }
  return Ok(twsAxis);
}

/// Egy adatsort `(twa, cells)` rekorddá alakít, vagy [PolarMalformedRow]-t
/// ad a [lineNumber]-rel és emberi okkal. A [previousTwa] a szigorú
/// monotonitás ellenőrzéséhez kell.
Result<({double twa, List<double?> cells}), PolarLoadError> _parseDataRow({
  required String line,
  required int lineNumber,
  required int twsCount,
  required double? previousTwa,
}) {
  final fields = line.split(';');
  final expected = twsCount + 1;
  if (fields.length != expected) {
    return Err(
      PolarMalformedRow(
        lineNumber: lineNumber,
        reason: 'mezőszám ${fields.length}, várt $expected',
      ),
    );
  }

  final twa = double.tryParse(fields.first.trim());
  if (twa == null) {
    return Err(
      PolarMalformedRow(
        lineNumber: lineNumber,
        reason: 'a TWA nem szám: "${fields.first.trim()}"',
      ),
    );
  }
  if (twa < 0 || twa > 180) {
    return Err(
      PolarMalformedRow(
        lineNumber: lineNumber,
        reason: 'a TWA a 0–180° tartományon kívül: $twa',
      ),
    );
  }
  if (previousTwa != null && twa <= previousTwa) {
    return Err(
      PolarMalformedRow(
        lineNumber: lineNumber,
        reason: 'a TWA nem szigorúan növekvő: $twa <= $previousTwa',
      ),
    );
  }

  final cells = <double?>[];
  for (final field in fields.skip(1)) {
    final trimmed = field.trim();
    if (trimmed.isEmpty) {
      cells.add(null);
      continue;
    }
    final value = double.tryParse(trimmed);
    if (value == null) {
      return Err(
        PolarMalformedRow(
          lineNumber: lineNumber,
          reason: 'a cella nem szám: "$trimmed"',
        ),
      );
    }
    // A 0.00 az üres-vödör sentinelje (A5) → a domain-rácsban null.
    cells.add(value == 0 ? null : value);
  }

  return Ok((twa: twa, cells: cells));
}

/// Igaz, ha a tengely szigorúan növekvő (nincs ismétlődés, nincs esés).
bool _isStrictlyAscending(List<double> axis) {
  for (var i = 1; i < axis.length; i++) {
    if (axis[i] <= axis[i - 1]) return false;
  }
  return true;
}
