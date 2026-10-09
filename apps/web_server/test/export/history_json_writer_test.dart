import 'dart:convert';
import 'dart:io';

import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';
import 'package:web_server/src/export/history_json_writer.dart';

// A JSON-iro hamis olvasokkal: a szerkezet, a sorrend es a hianyzo
// reszletezo kihagyasa. A versenyek a szerzodes kodolojaval mennek ki, igy
// a szerzodes dekodere visszaolvassa oket.

// Egy ervenyes nap szovegebol: a parse itt nem lehet null.
final CalendarDate _day = CalendarDate.tryParse('2024-07-25')!;

RaceSummary _summary(String id) => RaceSummary(
  id: id,
  name: 'Verseny $id',
  origin: ManualOrigin(_day),
  stats: const RaceStats(window: ManualEntry()),
);

void main() {
  late Directory directory;
  late List<String> logLines;
  final exportedAt = DateTime.utc(2026, 10, 6, 9, 30);

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('history_json');
    logLines = [];
  });

  tearDown(() => directory.delete(recursive: true));

  Future<(int, Map<String, Object?>)> write(
    List<RaceSummary> summaries, {
    Set<String> missingDetails = const {},
  }) async {
    final file = File('${directory.path}/history.json');
    final sink = file.openWrite();
    final count = await HistoryJsonWriter(
      readSummaries: () async => summaries,
      readDetail: (id) async => missingDetails.contains(id)
          ? null
          : RaceDetail(
              summary: summaries.firstWhere((summary) => summary.id == id),
            ),
      log: logLines.add,
    ).write(sink, exportedAt: exportedAt);
    await sink.close();
    final json = jsonDecode(await file.readAsString()) as Map<String, Object?>;
    return (count, json);
  }

  test('writes the envelope with the export time in UTC', () async {
    final (count, json) = await write([]);

    expect(count, 0);
    expect(json, {
      'format': 'foretack-history',
      'version': 1,
      'exportedAt': '2026-10-06T09:30:00.000Z',
      'races': <Object?>[],
    });
  });

  test('writes every race in the order of the log', () async {
    final (count, json) = await write([_summary('b'), _summary('a')]);
    final races = json['races']! as List<Object?>;

    expect(count, 2);
    final ids = [
      for (final race in races)
        switch (decodeRaceDetail(race)) {
          Ok(:final value) => value.summary.id,
          Err(:final error) => fail('$error'),
        },
    ];
    expect(ids, ['b', 'a']);
  });

  test('skips a race without a detail and logs it', () async {
    final (count, json) = await write(
      [_summary('a'), _summary('gone'), _summary('c')],
      missingDetails: {'gone'},
    );

    expect(count, 2);
    expect(json['races'], hasLength(2));
    expect(logLines.single, contains('gone'));
  });
}
