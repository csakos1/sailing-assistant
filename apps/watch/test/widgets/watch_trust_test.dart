import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watch/theme/watch_colors.dart';
import 'package:watch/widgets/watch_trust.dart';

void main() {
  const colors = WatchColors(
    background: Color(0xFF000001),
    surface: Color(0xFF000002),
    text: Color(0xFF000003),
    textSecondary: Color(0xFF000004),
    textTertiary: Color(0xFF000005),
    signal: Color(0xFF000006),
    critical: Color(0xFF000007),
    port: Color(0xFF000008),
    starboard: Color(0xFF000009),
    amber: Color(0xFF00000A),
  );

  group('isTwdHeld', () {
    test('true only for the held string', () {
      expect(isTwdHeld('held'), isTrue);
      expect(isTwdHeld('live'), isFalse);
      expect(isTwdHeld('unavailable'), isFalse);
      expect(isTwdHeld(null), isFalse);
      expect(isTwdHeld('garbage'), isFalse);
    });
  });

  group('confidenceArc', () {
    test('maps each confidence to a colour and a length', () {
      expect(confidenceArc('high', colors)?.color, colors.signal);
      expect(confidenceArc('high', colors)?.fraction, 1);

      expect(confidenceArc('medium', colors)?.color, colors.amber);
      expect(confidenceArc('medium', colors)?.fraction, lessThan(1));

      expect(confidenceArc('low', colors)?.color, colors.textTertiary);
      expect(
        confidenceArc('low', colors)?.fraction,
        lessThan(confidenceArc('medium', colors)!.fraction),
      );
    });

    test('null for missing or unknown values', () {
      expect(confidenceArc(null, colors), isNull);
      expect(confidenceArc('garbage', colors), isNull);
    });
  });
}
