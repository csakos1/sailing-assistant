import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/app/warning_colors.dart';

void main() {
  const colors = WarningColors(
    critical: Color(0xFFB3261E),
    warning: Color(0xFFE0A82E),
    info: Color(0xFF24323F),
  );

  group('WarningColors', () {
    test('backgroundFor minden severityre a megfelelő szín', () {
      expect(colors.backgroundFor(WarningSeverity.critical), colors.critical);
      expect(colors.backgroundFor(WarningSeverity.warning), colors.warning);
      expect(colors.backgroundFor(WarningSeverity.info), colors.info);
    });

    test('copyWith csak a megadott mezőt cseréli', () {
      final updated = colors.copyWith(warning: const Color(0xFF000000));
      expect(updated.warning, const Color(0xFF000000));
      expect(updated.critical, colors.critical);
      expect(updated.info, colors.info);
    });

    test('lerp nem-WarningColors targetre önmagát adja', () {
      expect(colors.lerp(null, 0.5), same(colors));
    });
  });
}
