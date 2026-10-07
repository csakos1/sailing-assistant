import 'package:test/test.dart';
import 'package:web_server/src/geoip/csv_line.dart';

void main() {
  test('splits plain and quoted fields like the DB-IP file', () {
    expect(
      parseCsvLine(
        '1.0.0.0,1.0.0.255,OC,AU,Queensland,"South Brisbane",-27.4767,153.017',
      ),
      [
        '1.0.0.0',
        '1.0.0.255',
        'OC',
        'AU',
        'Queensland',
        'South Brisbane',
        '-27.4767',
        '153.017',
      ],
    );
  });

  test('keeps commas, colons and doubled quotes inside quotes', () {
    expect(parseCsvLine('a,"b, c","San Diego (Mid-City:x)","say ""hi"""'), [
      'a',
      'b, c',
      'San Diego (Mid-City:x)',
      'say "hi"',
    ]);
  });

  test('keeps empty fields', () {
    expect(parseCsvLine('0.0.0.0,0.255.255.255,ZZ,ZZ,,,0,0'), [
      '0.0.0.0',
      '0.255.255.255',
      'ZZ',
      'ZZ',
      '',
      '',
      '0',
      '0',
    ]);
  });

  test('refuses broken quoting', () {
    for (final line in ['a,"b', 'a,b"c', 'a,"b"c']) {
      expect(parseCsvLine(line), isNull, reason: line);
    }
  });
}
