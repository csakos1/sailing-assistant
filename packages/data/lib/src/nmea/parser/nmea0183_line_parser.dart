import 'package:data/src/nmea/parser/parse_error.dart';
import 'package:data/src/nmea/parser/sentence.dart';
import 'package:shared/shared.dart';

/// Egyetlen NMEA 0183 sort `Sentence`-szé alakít a `*` XOR checksum
/// ellenőrzésével.
///
/// A bemenet nyers mondat (`$`/`!` … `*HH`), időbélyeg-prefix nélkül: a
/// felvett logok prefixét a replay-réteg távolítja el (ARCHITECTURE.md
/// 12.4). Hibás bemenetre [ParseError]-t ad `Err`-ben, sosem dob kivételt.
class Nmea0183LineParser {
  /// Állapotmentes parser; a default ctor const.
  const Nmea0183LineParser();

  /// A [line]-t `Sentence`-szé alakítja, vagy [ParseError]-t ad vissza.
  Result<Sentence, ParseError> parse(String line) {
    // A LineSplitter elhagyja a sorvégi '\n'-t, de a Vulcan '\r\n'-t küld,
    // ezért a maradék '\r'-t (és minden szél-whitespace-t) levágjuk.
    final trimmed = line.trim();
    if (trimmed.isEmpty) {
      return const Err(ParseError.empty);
    }

    // Kezdő delimiter: '$' (standard) vagy '!' (encapsulated, pl. AIS).
    final start = trimmed[0];
    if (start != r'$' && start != '!') {
      return const Err(ParseError.malformed);
    }

    // A checksumot az utolsó '*' után pontosan két hex karakter adja.
    final starIndex = trimmed.lastIndexOf('*');
    if (starIndex < 0 || starIndex != trimmed.length - 3) {
      return const Err(ParseError.malformed);
    }
    final expected = int.tryParse(trimmed.substring(starIndex + 1), radix: 16);
    if (expected == null) {
      return const Err(ParseError.malformed);
    }

    // Az XOR-t a delimiter (kizárva) és a '*' (kizárva) közti payloadon
    // számoljuk.
    final payload = trimmed.substring(1, starIndex);
    var actual = 0;
    for (final codeUnit in payload.codeUnits) {
      actual ^= codeUnit;
    }
    if (actual != expected) {
      return const Err(ParseError.checksumMismatch);
    }

    // Az address-token a payload első mezője (talker[2] + type, pl.
    // 'WIMWV'); standard 0183-ban legalább 5 karakter.
    final tokens = payload.split(',');
    final address = tokens.first;
    if (address.length < 5) {
      return const Err(ParseError.malformed);
    }

    return Ok(
      Sentence(
        talker: address.substring(0, 2),
        type: address.substring(2),
        fields: tokens.sublist(1),
        raw: line,
      ),
    );
  }
}
