import 'package:flutter_test/flutter_test.dart';
import 'package:watch/widgets/watch_trust.dart';

void main() {
  group('isTwdHeld', () {
    test('true only for the held string', () {
      expect(isTwdHeld('held'), isTrue);
      expect(isTwdHeld('live'), isFalse);
      expect(isTwdHeld('unavailable'), isFalse);
      expect(isTwdHeld(null), isFalse);
      expect(isTwdHeld('garbage'), isFalse);
    });
  });

  group('confidenceDotCount', () {
    test('maps the known confidence names to 1..3', () {
      expect(confidenceDotCount('low'), 1);
      expect(confidenceDotCount('medium'), 2);
      expect(confidenceDotCount('high'), 3);
    });

    test('null for missing or unknown values', () {
      expect(confidenceDotCount(null), isNull);
      expect(confidenceDotCount('garbage'), isNull);
    });
  });
}
