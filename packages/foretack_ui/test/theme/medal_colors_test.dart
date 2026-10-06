import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_ui/foretack_ui.dart';

void main() {
  const medals = MedalColors(
    gold: Color(0xFFE3B341),
    silver: Color(0xFFB4C2CE),
    bronze: Color(0xFFC98A55),
  );

  test('copyWith replaces only the given field', () {
    final updated = medals.copyWith(silver: const Color(0xFF112233));

    expect(updated.silver, const Color(0xFF112233));
    expect(updated.gold, medals.gold);
    expect(updated.bronze, medals.bronze);
  });

  test('lerp reaches the other extension at t = 1', () {
    const other = MedalColors(
      gold: Color(0xFF000000),
      silver: Color(0xFF000001),
      bronze: Color(0xFF000002),
    );

    final mixed = medals.lerp(other, 1);

    expect(mixed.gold, other.gold);
    expect(mixed.silver, other.silver);
    expect(mixed.bronze, other.bronze);
  });

  test('lerp returns this for a foreign extension', () {
    expect(medals.lerp(null, 0.5), same(medals));
  });
}
