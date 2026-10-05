import 'package:domain/domain.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';
import 'package:web_server/src/legacy/legacy_csv_slice.dart';
import 'package:web_server/src/legacy/legacy_track_sample.dart';
import 'package:web_server/src/legacy/slice_ydvr_csv.dart';
import 'package:web_server/src/legacy/ydvr_csv_problem.dart';

// A CSV ido-oszlopa budapesti helyi ido; 2023. julius 1-jen UTC+2, igy a
// 12:00:00 helyi sor 10:00:00 UTC.
const _header =
    'Time,Latitude,Longitude,SOG,STW,'
    'TWS,TWD(med),TWS(med),TWA(med)';

String _line(String localTime, {String lat = '46.95', String sog = '6'}) =>
    '2023-07-01 $localTime,$lat,17.9,$sog,5,10,200,9,315';

final _window = TimeWindow(
  start: DateTime.utc(2023, 7, 1, 10),
  end: DateTime.utc(2023, 7, 1, 10, 0, 20),
);

Future<LegacyCsvSlice> _slice(
  List<String> lines, {
  List<({String raceId, TimeWindow window})>? windows,
}) async {
  final result = await sliceYdvrCsv(
    Stream.fromIterable(lines),
    windows ?? [(raceId: 'm1', window: _window)],
  );
  return switch (result) {
    Ok(:final value) => value,
    Err(:final error) => throw StateError('$error'),
  };
}

List<DateTime> _timesOf(LegacyCsvSlice slice, String raceId) => [
  for (final sample in slice.tracks[raceId] ?? const <LegacyTrackSample>[])
    sample.timestamp,
];

void main() {
  test('keeps the rows inside the window, bounds included', () async {
    // ARRANGE
    final lines = [
      _header,
      _line('11:59:50'),
      _line('12:00:00'),
      _line('12:00:10'),
      _line('12:00:20'),
      _line('12:00:30'),
    ];

    // ACT
    final slice = await _slice(lines);

    // ASSERT
    expect(_timesOf(slice, 'm1'), [
      DateTime.utc(2023, 7, 1, 10),
      DateTime.utc(2023, 7, 1, 10, 0, 10),
      DateTime.utc(2023, 7, 1, 10, 0, 20),
    ]);
    expect(slice.rowCount, 5);
    expect(slice.problemCount, 0);
  });

  test('serves overlapping windows of two races from one row', () async {
    // ARRANGE
    final second = TimeWindow(
      start: DateTime.utc(2023, 7, 1, 10, 0, 10),
      end: DateTime.utc(2023, 7, 1, 11),
    );
    final lines = [_header, _line('12:00:00'), _line('12:00:10')];

    // ACT
    final slice = await _slice(
      lines,
      windows: [
        (raceId: 'm2', window: second),
        (raceId: 'm1', window: _window),
      ],
    );

    // ASSERT
    expect(_timesOf(slice, 'm1'), hasLength(2));
    expect(_timesOf(slice, 'm2'), [DateTime.utc(2023, 7, 1, 10, 0, 10)]);
  });

  test('sorts unordered rows and keeps the later of a duplicate', () async {
    // ARRANGE
    final lines = [
      _header,
      _line('12:00:10'),
      _line('12:00:00', sog: '4'),
      _line('12:00:00', sog: '8'),
    ];

    // ACT
    final slice = await _slice(lines);

    // ASSERT
    final samples = slice.tracks['m1']!;
    expect(_timesOf(slice, 'm1'), [
      DateTime.utc(2023, 7, 1, 10),
      DateTime.utc(2023, 7, 1, 10, 0, 10),
    ]);
    expect(samples.first.sogMps, closeTo(8 * 1852 / 3600, 1e-12));
  });

  test('skips bad rows and reports the first one', () async {
    // ARRANGE: line 3 is outside the window but has a broken time; line 4
    // is inside with a broken number; line 5 is fine
    final lines = [
      _header,
      _line('12:00:00'),
      'not-a-time,46.95,17.9,6,5,10,200,9,315',
      _line('12:00:10', lat: 'x'),
      _line('12:00:20'),
    ];

    // ACT
    final slice = await _slice(lines);

    // ASSERT
    expect(slice.problemCount, 2);
    expect(slice.firstProblem, (
      lineNumber: 3,
      problem: const YdvrCsvRowProblem(
        YdvrCsvProblemKind.time,
        column: 'Time',
      ),
    ));
    expect(_timesOf(slice, 'm1'), hasLength(2));
  });

  test('does not parse the samples of rows outside every window', () async {
    // ARRANGE: a broken number outside the window is not a problem
    final lines = [_header, _line('13:00:00', lat: 'x')];

    // ACT
    final slice = await _slice(lines);

    // ASSERT
    expect(slice.problemCount, 0);
    expect(slice.tracks, isEmpty);
  });

  test('ignores blank lines', () async {
    final slice = await _slice([_header, '', _line('12:00:00'), '  ']);

    expect(slice.rowCount, 1);
    expect(slice.problemCount, 0);
  });

  test('fails on a header without the required columns', () async {
    final result = await sliceYdvrCsv(
      Stream.fromIterable(['Time,Latitude,Longitude', _line('12:00:00')]),
      [(raceId: 'm1', window: _window)],
    );

    expect(result, isA<Err<LegacyCsvSlice, YdvrCsvHeaderError>>());
  });

  test('fails on an empty file', () async {
    final result = await sliceYdvrCsv(const Stream.empty(), [
      (raceId: 'm1', window: _window),
    ]);

    expect(
      result,
      const Err<LegacyCsvSlice, YdvrCsvHeaderError>(
        YdvrCsvHeaderError(
          missing: [
            'Time',
            'Latitude',
            'Longitude',
            'SOG',
            'STW',
            'TWS',
            'TWD(med)',
            'TWS(med)',
            'TWA(med)',
          ],
        ),
      ),
    );
  });
}
