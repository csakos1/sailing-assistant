import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watch/theme/watch_colors.dart';

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
  );

  group('WatchColors', () {
    test('copyWith overrides only the given field', () {
      final updated = colors.copyWith(signal: const Color(0xFF0000AA));

      expect(updated.signal, const Color(0xFF0000AA));
      expect(updated.background, colors.background);
      expect(updated.starboard, colors.starboard);
    });

    test('lerp returns the endpoints at t=0 and t=1', () {
      const other = WatchColors(
        background: Color(0xFF0000F1),
        surface: Color(0xFF0000F2),
        text: Color(0xFF0000F3),
        textSecondary: Color(0xFF0000F4),
        textTertiary: Color(0xFF0000F5),
        signal: Color(0xFF0000F6),
        critical: Color(0xFF0000F7),
        port: Color(0xFF0000F8),
        starboard: Color(0xFF0000F9),
      );

      expect(colors.lerp(other, 0).signal, colors.signal);
      expect(colors.lerp(other, 1).signal, other.signal);
    });

    test('lerp with a non-WatchColors other returns this', () {
      expect(colors.lerp(null, 0.5), same(colors));
    });
  });
}
