import 'package:flutter_test/flutter_test.dart';
import 'package:phone/format/elapsed_format.dart';

void main() {
  test('formats hours, minutes and seconds with two digits', () {
    expect(
      formatElapsed(const Duration(minutes: 42, seconds: 10)),
      '00:42:10',
    );
  });

  test('keeps counting the hours past a day', () {
    // Egy ketnapos Kekszalag nem fordul at nullara.
    expect(
      formatElapsed(const Duration(hours: 30, minutes: 12, seconds: 5)),
      '30:12:05',
    );
  });

  test('writes a negative duration as zero', () {
    expect(formatElapsed(const Duration(seconds: -5)), '00:00:00');
  });
}
