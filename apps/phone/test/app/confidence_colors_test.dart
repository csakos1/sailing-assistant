import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/app/confidence_colors.dart';

void main() {
  const colors = ConfidenceColors(
    low: Color(0xFF111111),
    medium: Color(0xFF222222),
    high: Color(0xFF333333),
  );

  group('ConfidenceColors', () {
    test('forConfidence maps each level to its colour', () {
      expect(
        colors.forConfidence(WindShiftConfidence.low),
        const Color(0xFF111111),
      );
      expect(
        colors.forConfidence(WindShiftConfidence.medium),
        const Color(0xFF222222),
      );
      expect(
        colors.forConfidence(WindShiftConfidence.high),
        const Color(0xFF333333),
      );
    });

    test('copyWith overrides only the given field', () {
      final updated = colors.copyWith(medium: const Color(0xFF999999));

      expect(updated.low, colors.low);
      expect(updated.medium, const Color(0xFF999999));
      expect(updated.high, colors.high);
    });

    test('lerp returns the endpoints at t=0 and t=1', () {
      const other = ConfidenceColors(
        low: Color(0xFFAAAAAA),
        medium: Color(0xFFBBBBBB),
        high: Color(0xFFCCCCCC),
      );

      expect(colors.lerp(other, 0).low, colors.low);
      expect(colors.lerp(other, 1).low, other.low);
    });
  });
}
