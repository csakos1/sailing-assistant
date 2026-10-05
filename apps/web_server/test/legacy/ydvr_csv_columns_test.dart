import 'package:shared/shared.dart';
import 'package:test/test.dart';
import 'package:web_server/src/legacy/legacy_track_sample.dart';
import 'package:web_server/src/legacy/ydvr_csv_columns.dart';
import 'package:web_server/src/legacy/ydvr_csv_problem.dart';

// A fejlec a valodi polar.csv sorrendjet koveti, roviditve: a nem hasznalt
// oszlopok kozul egy-egy marad, hogy a nev szerinti kereses latszodjon.
const _header =
    'Time,Latitude,Longitude,TWS,TWS(med),TWD(med),TWA,TWA(med),'
    'AWS,STW,COG,SOG';

// Egy minta a fenti sorrendben; a cellak indexe a fejleche.
List<String> _row({
  String time = '2023-07-01 10:30:06',
  String lat = '46.93781',
  String lon = '17.95033',
  String tws = '10',
  String twsMedian = '9',
  String twdMedian = '200',
  String twaMedian = '315',
  String stw = '5',
  String sog = '6',
}) => [
  time,
  lat,
  lon,
  tws,
  twsMedian,
  twdMedian,
  '316',
  twaMedian,
  '12',
  stw,
  '180',
  sog,
];

const double _knot = 1852 / 3600;

YdvrCsvColumns _columns() => switch (YdvrCsvColumns.fromHeader(_header)) {
  Ok(:final value) => value,
  Err(:final error) => throw StateError('$error'),
};

void main() {
  group('YdvrCsvColumns.fromHeader', () {
    test('accepts the columns in any order with extra ones', () {
      expect(YdvrCsvColumns.fromHeader(_header), isA<Ok<Object, Object>>());
    });

    test('ignores a byte order mark before the first header', () {
      final result = YdvrCsvColumns.fromHeader('\uFEFF$_header');

      expect(result, isA<Ok<Object, Object>>());
    });

    test('lists the missing required columns', () {
      final result = YdvrCsvColumns.fromHeader('Time,Latitude,Longitude,SOG');

      expect(
        result,
        const Err<YdvrCsvColumns, YdvrCsvHeaderError>(
          YdvrCsvHeaderError(
            missing: ['STW', 'TWS', 'TWD(med)', 'TWS(med)', 'TWA(med)'],
          ),
        ),
      );
    });

    test('rejects a duplicated required column', () {
      final result = YdvrCsvColumns.fromHeader('$_header,SOG');

      expect(
        result,
        const Err<YdvrCsvColumns, YdvrCsvHeaderError>(
          YdvrCsvHeaderError(duplicated: ['SOG']),
        ),
      );
    });
  });

  group('YdvrCsvColumns.timestampOf', () {
    test('reads a summer wall clock as UTC+2', () {
      final result = _columns().timestampOf(_row());

      expect(
        result,
        Ok<DateTime, YdvrCsvRowProblem>(DateTime.utc(2023, 7, 1, 8, 30, 6)),
      );
    });

    test('reads a winter wall clock as UTC+1', () {
      final result = _columns().timestampOf(_row(time: '2023-03-25 10:00:00'));

      expect(
        result,
        Ok<DateTime, YdvrCsvRowProblem>(DateTime.utc(2023, 3, 25, 9)),
      );
    });

    test('rejects a row with a different cell count', () {
      final result = _columns().timestampOf(_row().sublist(1));

      expect(
        result,
        const Err<DateTime, YdvrCsvRowProblem>(
          YdvrCsvRowProblem(YdvrCsvProblemKind.cellCount),
        ),
      );
    });

    test('rejects a day that does not exist', () {
      final result = _columns().timestampOf(_row(time: '2023-02-30 10:00:00'));

      expect(
        result,
        const Err<DateTime, YdvrCsvRowProblem>(
          YdvrCsvRowProblem(YdvrCsvProblemKind.time, column: 'Time'),
        ),
      );
    });

    test('rejects another time format', () {
      final result = _columns().timestampOf(_row(time: '2023.07.01 10:30'));

      expect(result, isA<Err<DateTime, YdvrCsvRowProblem>>());
    });
  });

  group('YdvrCsvColumns.sampleOf', () {
    final timestamp = DateTime.utc(2023, 7, 1, 8, 30, 6);

    LegacyTrackSample sampleOf(List<String> cells) =>
        switch (_columns().sampleOf(cells, timestamp)) {
          Ok(:final value) => value,
          Err(:final error) => throw StateError('$error'),
        };

    test('converts knots to metres per second', () {
      final sample = sampleOf(_row());

      expect(sample.sogMps, closeTo(6 * _knot, 1e-12));
      expect(sample.stwMps, closeTo(5 * _knot, 1e-12));
      expect(sample.twsMps, closeTo(10 * _knot, 1e-12));
      expect(sample.polarTwsMps, closeTo(9 * _knot, 1e-12));
    });

    test('keeps the position, the time and the median direction', () {
      final sample = sampleOf(_row());

      expect(sample.timestamp, timestamp);
      expect(sample.latDeg, 46.93781);
      expect(sample.lonDeg, 17.95033);
      expect(sample.twdDeg, 200);
    });

    test('turns an angle above 180 into a negative port angle', () {
      expect(sampleOf(_row()).polarTwaDeg, -45);
    });

    test('keeps a starboard angle and 180 as they are', () {
      expect(sampleOf(_row(twaMedian: '45')).polarTwaDeg, 45);
      expect(sampleOf(_row(twaMedian: '180')).polarTwaDeg, 180);
    });

    test('normalizes a full-circle direction to zero', () {
      expect(sampleOf(_row(twdMedian: '360')).twdDeg, 0);
    });

    test('reads an empty cell as null', () {
      final sample = sampleOf(_row(lat: '', lon: '', tws: '', sog: ''));

      expect(sample.latDeg, isNull);
      expect(sample.lonDeg, isNull);
      expect(sample.twsMps, isNull);
      expect(sample.sogMps, isNull);
    });

    test('rejects an unreadable number with its column', () {
      final result = _columns().sampleOf(_row(stw: 'abc'), timestamp);

      expect(
        result,
        const Err<LegacyTrackSample, YdvrCsvRowProblem>(
          YdvrCsvRowProblem(YdvrCsvProblemKind.number, column: 'STW'),
        ),
      );
    });

    test('rejects a non-finite number', () {
      final result = _columns().sampleOf(_row(tws: 'NaN'), timestamp);

      expect(
        result,
        const Err<LegacyTrackSample, YdvrCsvRowProblem>(
          YdvrCsvRowProblem(YdvrCsvProblemKind.number, column: 'TWS'),
        ),
      );
    });

    test('rejects a latitude outside the globe', () {
      final result = _columns().sampleOf(_row(lat: '91'), timestamp);

      expect(
        result,
        const Err<LegacyTrackSample, YdvrCsvRowProblem>(
          YdvrCsvRowProblem(
            YdvrCsvProblemKind.coordinate,
            column: 'Latitude',
          ),
        ),
      );
    });

    test('reports the first bad cell only', () {
      final result = _columns().sampleOf(
        _row(lat: '-95', sog: 'x'),
        timestamp,
      );

      expect(
        result,
        const Err<LegacyTrackSample, YdvrCsvRowProblem>(
          YdvrCsvRowProblem(
            YdvrCsvProblemKind.coordinate,
            column: 'Latitude',
          ),
        ),
      );
    });
  });

  test('splitYdvrCsvLine trims every cell', () {
    expect(splitYdvrCsvLine(' a, b ,,c'), ['a', 'b', '', 'c']);
  });
}
