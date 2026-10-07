import 'dart:io';

import 'package:shared/shared.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';
import 'package:web_server/src/geoip/geo_ip_builder.dart';
import 'package:web_server/src/geoip/geo_ip_database.dart';

const String _ipv6Sample =
    '2001:4c4c::,2001:4c4c:ffff:ffff:ffff:ffff:ffff:ffff,EU,HU,Budapest,'
    'Budapest,47.4984,19.0405';

const List<String> _sample = [
  '0.0.0.0,0.255.255.255,ZZ,ZZ,,,0,0',
  '1.0.0.0,1.0.0.255,OC,AU,Queensland,"South Brisbane",-27.4767,153.017',
  '5.38.128.0,5.38.191.255,EU,HU,Budapest,Budapest,47.4984,19.0405',
  '5.38.193.0,5.38.255.255,EU,HU,Somogy,Siófok,46.9041,18.058',
  _ipv6Sample,
];

void main() {
  late Directory temp;
  late String outPath;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('geoip-test-');
    outPath = '${temp.path}/geoip.sqlite';
  });

  tearDown(() => temp.deleteSync(recursive: true));

  Future<Result<GeoIpBuildSummary, GeoIpFormatError>> build(
    List<String> lines,
  ) => buildGeoIpDatabase(lines: Stream.fromIterable(lines), outPath: outPath);

  GeoIpDatabase open() => switch (GeoIpDatabase.open(outPath)) {
    Ok(:final value) => value,
    Err(:final error) => throw StateError('megnyithatot vartunk: $error'),
  };

  test('builds the ranges and counts them per family', () async {
    final result = await build(_sample);

    expect(
      result,
      const Ok<GeoIpBuildSummary, GeoIpFormatError>((
        ipv4Ranges: 4,
        ipv6Ranges: 1,
      )),
    );
    expect(File('$outPath.partial').existsSync(), isFalse);
  });

  test('finds the range at its start, end and inside', () async {
    await build(_sample);
    final database = open();
    addTearDown(database.close);

    expect(database.lookup('5.38.128.0'), (country: 'HU', city: 'Budapest'));
    expect(database.lookup('5.38.150.7'), (country: 'HU', city: 'Budapest'));
    expect(database.lookup('5.38.191.255'), (country: 'HU', city: 'Budapest'));
    expect(database.lookup('5.38.200.1'), (country: 'HU', city: 'Siófok'));
    expect(
      database.lookup('2001:4c4c::1234'),
      (country: 'HU', city: 'Budapest'),
    );
    expect(
      database.lookup('::ffff:5.38.150.7'),
      (country: 'HU', city: 'Budapest'),
    );
  });

  test('answers unknown for gaps, private, other family and junk', () async {
    await build(_sample);
    final database = open();
    addTearDown(database.close);

    for (final ip in [
      '5.38.192.10',
      '192.168.1.1',
      '2a01:4f8::1',
      'unknown',
      '0.1.2.3',
    ]) {
      expect(database.lookup(ip), (country: null, city: null), reason: ip);
    }
  });

  test('stops at a bad line and keeps the old database', () async {
    await build(_sample);
    final before = File(outPath).readAsBytesSync();

    final result = await build([..._sample.take(2), 'bad,line']);

    expect(result, isA<Err<GeoIpBuildSummary, GeoIpFormatError>>());
    expect(switch (result) {
      Err(:final error) => error.line,
      Ok() => null,
    }, 3);
    expect(File(outPath).readAsBytesSync(), before);
    expect(File('$outPath.partial').existsSync(), isFalse);
  });

  test('refuses a repeated range start', () async {
    final result = await build([_sample[1], _sample[1]]);

    expect(switch (result) {
      Err(:final error) => error.line,
      Ok() => null,
    }, 2);
  });

  test('refuses to open a file that is not a GeoIP database', () {
    final other = '${temp.path}/other.sqlite';
    sqlite3.open(other)
      ..execute('CREATE TABLE t (x INTEGER)')
      ..close();

    expect(GeoIpDatabase.open(other), isA<Err<GeoIpDatabase, String>>());
    expect(
      GeoIpDatabase.open('${temp.path}/missing.sqlite'),
      isA<Err<GeoIpDatabase, String>>(),
    );
  });
}
