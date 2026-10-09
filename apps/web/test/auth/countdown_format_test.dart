import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_web/auth/sign_in/countdown_format.dart';

void main() {
  test('formats minutes and zero-padded seconds', () {
    expect(formatCountdown(60), '1:00');
    expect(formatCountdown(42), '0:42');
    expect(formatCountdown(576), '9:36');
    expect(formatCountdown(600), '10:00');
  });

  test('never shows a negative time', () {
    expect(formatCountdown(0), '0:00');
    expect(formatCountdown(-3), '0:00');
  });
}
