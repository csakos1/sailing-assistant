import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:web_server/src/legacy/describe_legacy_tracks.dart';
import 'package:web_server/src/legacy/legacy_csv_slice.dart';
import 'package:web_server/src/legacy/legacy_track_plan_item.dart';
import 'package:web_server/src/legacy/ydvr_csv_problem.dart';

import 'legacy_track_fixtures.dart';

void main() {
  final start = DateTime.utc(2023, 7, 1, 10);
  final window = TimeWindow(
    start: start,
    end: start.add(const Duration(minutes: 1)),
  );
  const cleanSlice = LegacyCsvSlice(rowCount: 120, problemCount: 0, tracks: {});

  PlannedLegacyTrack planned({required double coverage}) => PlannedLegacyTrack(
    legacyManualRecord(
      'm1',
      name: 'Kekszalag',
      distanceMeters: 175600,
    ),
    window: window,
    samples: [legacyStepSample(start, 0), legacyStepSample(start, 1)],
    coverage: coverage,
    distanceMeters: 186340,
  );

  test('shows each track with its coverage and both distances', () {
    // ARRANGE
    const trackLine =
        '  2023-06-01 Kekszalag [m1] · 2 minta, 97 % lefedettség, '
        'táv 186,3 km (beírva: 175,6 km)';

    // ACT
    final lines = describeLegacyTracks(cleanSlice, [
      planned(coverage: 0.97),
    ]);

    // ASSERT
    expect(lines, [
      'CSV: 120 sor, hibás sor nincs',
      'Track kerül fel: 1',
      trackLine,
      'Nincs track (a korábbi törlődik): 0',
    ]);
  });

  test('warns below 80 percent coverage', () {
    final lines = describeLegacyTracks(cleanSlice, [planned(coverage: 0.5)]);

    expect(lines, contains('    FIGYELEM: a lefedettség 80 % alatti'));
  });

  test('tells why a race gets no track', () {
    // ARRANGE
    const tooShortLine =
        '  2023-06-01 Foldvar [m3] · kettőnél kevesebb pozíció '
        '(0 minta, 0 pozíció)';

    // ACT
    final lines = describeLegacyTracks(cleanSlice, [
      LegacyTrackWithoutWindow(legacyManualRecord('m2', name: 'Timu')),
      LegacyTrackTooShort(
        legacyManualRecord('m3', name: 'Foldvar'),
        window: window,
        sampleCount: 0,
        positionCount: 0,
      ),
    ]);

    // ASSERT
    expect(
      lines.skip(2),
      [
        'Nincs track (a korábbi törlődik): 2',
        '  2023-06-01 Timu [m2] · nincs hivatalos rajt és befutás',
        tooShortLine,
      ],
    );
  });

  test('reports the skipped rows with the first one', () {
    // ARRANGE
    const slice = LegacyCsvSlice(
      rowCount: 247179,
      problemCount: 2,
      firstProblem: (
        lineNumber: 1234,
        problem: YdvrCsvRowProblem(YdvrCsvProblemKind.number, column: 'TWS'),
      ),
      tracks: {},
    );

    // ACT
    final lines = describeLegacyTracks(slice, const []);

    // ASSERT
    expect(
      lines.first,
      'CSV: 247179 sor, 2 hibás sor kihagyva '
      '(első: 1234. sor, olvashatatlan szám: TWS)',
    );
  });

  test('shows an unknown distance as a dash', () {
    // ARRANGE
    final item = PlannedLegacyTrack(
      legacyManualRecord('m1', name: 'Kekszalag'),
      window: window,
      samples: const [],
      coverage: 1,
      distanceMeters: null,
    );

    // ACT
    final lines = describeLegacyTracks(cleanSlice, [item]);

    // ASSERT
    expect(lines[2], endsWith('táv – (beírva: –)'));
  });

  test('describes the apply report', () {
    expect(describeLegacyTrackApply((written: 56, cleared: 5)), [
      'Track írva: 56',
      'Track nélkül (törölve, ha volt): 5',
    ]);
  });
}
