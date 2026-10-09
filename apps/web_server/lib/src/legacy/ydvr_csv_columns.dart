import 'package:shared/shared.dart';
import 'package:web_server/src/legacy/budapest_time.dart';
import 'package:web_server/src/legacy/legacy_track_sample.dart';
import 'package:web_server/src/legacy/ydvr_csv_problem.dart';

/// A `polar.csv` kötelező oszlopai a fejléc szerint (ADR 0050 D3, D4 +
/// Addendum 1 E3).
///
/// A YDVRCONV kimenete vesszővel tagolt, idézőjel nélkül; a `Time` oszlop
/// Europe/Budapest helyi idő, a sebességek csomóban, a szögek fokban. Az
/// oszlopokat név szerint keresi, így a sorrendjük és a többi (itt nem
/// használt) oszlop nem számít.
///
/// Két lépésben olvas: a [timestampOf] csak az időt, a [sampleOf] a
/// mintát. A hivatalos ablakon kívüli sorok így csak az időbélyegig
/// bomlanak.
final class YdvrCsvColumns {
  YdvrCsvColumns._(this._indexOf, this._cellCount);

  /// Az oszlopok a [headerLine] fejlécből; hiba, ha egy kötelező oszlop
  /// hiányzik vagy ismétlődik.
  static Result<YdvrCsvColumns, YdvrCsvHeaderError> fromHeader(
    String headerLine,
  ) {
    // A fájl eleji BOM nem része az első fejlécnek.
    final cells = splitYdvrCsvLine(headerLine.replaceFirst('\uFEFF', ''));
    final missing = [
      for (final name in requiredColumns)
        if (!cells.contains(name)) name,
    ];
    final duplicated = [
      for (final name in requiredColumns)
        if (cells.where((cell) => cell == name).length > 1) name,
    ];
    if (missing.isNotEmpty || duplicated.isNotEmpty) {
      return Err(YdvrCsvHeaderError(missing: missing, duplicated: duplicated));
    }
    return Ok(
      YdvrCsvColumns._({
        for (final name in requiredColumns) name: cells.indexOf(name),
      }, cells.length),
    );
  }

  /// A kötelező oszlopok fejlécei.
  static const List<String> requiredColumns = [
    _time,
    _latitude,
    _longitude,
    _sog,
    _stw,
    _tws,
    _twdMedian,
    _twsMedian,
    _twaMedian,
  ];

  final Map<String, int> _indexOf;
  final int _cellCount;

  /// A [cells] sor pillanata (UTC), vagy a hiba oka.
  Result<DateTime, YdvrCsvRowProblem> timestampOf(List<String> cells) {
    if (cells.length != _cellCount) {
      return const Err(YdvrCsvRowProblem(YdvrCsvProblemKind.cellCount));
    }
    final wallClock = _parseWallClock(_cell(cells, _time));
    if (wallClock == null) {
      return const Err(
        YdvrCsvRowProblem(YdvrCsvProblemKind.time, column: _time),
      );
    }
    return Ok(budapestWallClockToUtc(wallClock));
  }

  /// A [cells] sor mintája a [timestamp] pillanattal (a [timestampOf]
  /// eredménye), vagy az első hibás cella oka.
  Result<LegacyTrackSample, YdvrCsvRowProblem> sampleOf(
    List<String> cells,
    DateTime timestamp,
  ) {
    final reader = _CellReader(cells, _indexOf);
    final sample = LegacyTrackSample(
      timestamp: timestamp,
      latDeg: reader.coordinate(_latitude, limit: 90),
      lonDeg: reader.coordinate(_longitude, limit: 180),
      sogMps: reader.speed(_sog),
      stwMps: reader.speed(_stw),
      twsMps: reader.speed(_tws),
      twdDeg: reader.direction(_twdMedian),
      polarTwsMps: reader.speed(_twsMedian),
      polarTwaDeg: reader.signedAngle(_twaMedian),
    );
    return switch (reader.firstProblem) {
      null => Ok(sample),
      final YdvrCsvRowProblem problem => Err(problem),
    };
  }

  String _cell(List<String> cells, String column) =>
      // A fromHeader minden kötelező oszlopnak indexet ad.
      cells[_indexOf[column]!];
}

/// Egy `polar.csv`-sor cellái, szélükön a szóközök nélkül.
///
/// A YDVRCONV nem idéz, és a cellákban nincs vessző, ezért az egyszerű
/// vágás pontos.
List<String> splitYdvrCsvLine(String line) => [
  for (final cell in line.split(',')) cell.trim(),
];

const String _time = 'Time';
const String _latitude = 'Latitude';
const String _longitude = 'Longitude';
const String _sog = 'SOG';
const String _stw = 'STW';
const String _tws = 'TWS';
const String _twdMedian = 'TWD(med)';
const String _twsMedian = 'TWS(med)';
const String _twaMedian = 'TWA(med)';

// 1 csomó = 1852 m / 3600 s, pontosan.
const double _metersPerSecondPerKnot = 1852 / 3600;

final RegExp _wallClockPattern = RegExp(
  r'^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})$',
);

// A mezők egy UTC-objektumban, ahogy a budapestWallClockToUtc várja. Egy
// nem létező napot (02-30) a DateTime átgörgetne, ezért a mezőket
// visszaellenőrzi.
DateTime? _parseWallClock(String text) {
  final match = _wallClockPattern.firstMatch(text);
  if (match == null) return null;
  final fields = [
    // A minta hat kötelező csoportja csupa számjegy.
    for (var group = 1; group <= 6; group++) int.parse(match.group(group)!),
  ];
  final wallClock = DateTime.utc(
    fields[0],
    fields[1],
    fields[2],
    fields[3],
    fields[4],
    fields[5],
  );
  final isExact =
      wallClock.year == fields[0] &&
      wallClock.month == fields[1] &&
      wallClock.day == fields[2] &&
      wallClock.hour == fields[3] &&
      wallClock.minute == fields[4] &&
      wallClock.second == fields[5];
  return isExact ? wallClock : null;
}

// Egy sor celláinak olvasója: a hibás cella `null`-t ad, és az első hiba
// oka megmarad. Így a minta egy menetben épül, kivétel nélkül.
final class _CellReader {
  _CellReader(this._cells, this._indexOf);

  final List<String> _cells;
  final Map<String, int> _indexOf;

  YdvrCsvRowProblem? firstProblem;

  double? speed(String column) => switch (_number(column)) {
    null => null,
    final double knots => knots * _metersPerSecondPerKnot,
  };

  double? coordinate(String column, {required double limit}) {
    final value = _number(column);
    if (value == null || value.abs() <= limit) return value;
    _fail(YdvrCsvProblemKind.coordinate, column);
    return null;
  }

  // A Dart `%` pozitív osztóval nem negatív, így a −10° 350° lesz.
  double? direction(String column) => switch (_number(column)) {
    null => null,
    final double degrees => degrees % 360,
  };

  // A CSV TWA-ja 0–360°; a domain előjeles: a 180° fölötti a bal halz.
  double? signedAngle(String column) {
    final degrees = _number(column);
    if (degrees == null) return null;
    final normalized = degrees % 360;
    return normalized > 180 ? normalized - 360 : normalized;
  }

  double? _number(String column) {
    // A fromHeader minden kötelező oszlopnak indexet ad.
    final text = _cells[_indexOf[column]!];
    if (text.isEmpty) return null;
    final value = double.tryParse(text);
    if (value != null && value.isFinite) return value;
    _fail(YdvrCsvProblemKind.number, column);
    return null;
  }

  void _fail(YdvrCsvProblemKind kind, String column) {
    firstProblem ??= YdvrCsvRowProblem(kind, column: column);
  }
}
