import 'package:shared/shared.dart';
import 'package:test/test.dart';
import 'package:web_server/src/geoip/dbip_city_row.dart';

GeoIpRange _ok(String line) => switch (parseDbIpCityRow(line)) {
  Ok(:final value) => value,
  Err(:final error) => throw StateError('Ok-t vartunk: $error'),
};

String _error(String line) => switch (parseDbIpCityRow(line)) {
  Ok(:final value) => throw StateError('Err-t vartunk: $value'),
  Err(:final error) => error,
};

void main() {
  test('reads an IPv4 row with a quoted city', () {
    final range = _ok(
      '1.0.0.0,1.0.0.255,OC,AU,Queensland,"South Brisbane",-27.4767,153.017',
    );

    expect(range.family, 4);
    expect(range.start, [1, 0, 0, 0]);
    expect(range.end, [1, 0, 0, 255]);
    expect(range.country, 'AU');
    expect(range.city, 'South Brisbane');
  });

  test('reads the reserved ZZ range as an unknown place', () {
    final range = _ok('0.0.0.0,0.255.255.255,ZZ,ZZ,,,0,0');

    expect(range.country, isNull);
    expect(range.city, isNull);
  });

  test('reads an IPv6 row as sixteen bytes', () {
    final range = _ok(
      '2001:4c4c::,2001:4c4c:ffff:ffff:ffff:ffff:ffff:ffff,EU,HU,Budapest,'
      'Budapest,47.4984,19.0405',
    );

    expect(range.family, 6);
    expect(range.start, hasLength(16));
    expect(range.country, 'HU');
  });

  test('keeps an IPv4-mapped IPv6 range in the IPv6 family', () {
    final range = _ok('::ffff:0.0.0.0,::ffff:255.255.255.255,ZZ,ZZ,,,0,0');

    expect(range.family, 6);
  });

  test('refuses a changed format', () {
    expect(_error('1.0.0.0,1.0.0.255,OC,AU,Queensland,x,1'), contains('7'));
    expect(_error('x,1.0.0.255,OC,AU,Q,x,1,2'), contains('IP'));
    expect(_error('1.0.0.0,::1,OC,AU,Q,x,1,2'), contains('IPv6'));
    expect(_error('1.0.0.9,1.0.0.1,OC,AU,Q,x,1,2'), contains('vége'));
  });
}
