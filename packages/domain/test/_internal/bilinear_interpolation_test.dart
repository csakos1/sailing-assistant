import 'package:domain/src/_internal/bilinear_interpolation.dart';
import 'package:test/test.dart';

void main() {
  group('bilinearInterpolate', () {
    group('mind a négy sarok adott', () {
      test('(0,0) frakció → a low-low sarok pontosan', () {
        // Arrange / Act
        final result = bilinearInterpolate(
          lowTwaLowTws: 10,
          lowTwaHighTws: 20,
          highTwaLowTws: 30,
          highTwaHighTws: 40,
          twaFraction: 0,
          twsFraction: 0,
        );

        // Assert
        expect(result, closeTo(10, 1e-9));
      });

      test('(1,1) frakció → a high-high sarok pontosan', () {
        final result = bilinearInterpolate(
          lowTwaLowTws: 10,
          lowTwaHighTws: 20,
          highTwaLowTws: 30,
          highTwaHighTws: 40,
          twaFraction: 1,
          twsFraction: 1,
        );

        expect(result, closeTo(40, 1e-9));
      });

      test('cella-közép (0.5,0.5) → a négy sarok átlaga', () {
        final result = bilinearInterpolate(
          lowTwaLowTws: 10,
          lowTwaHighTws: 20,
          highTwaLowTws: 30,
          highTwaHighTws: 40,
          twaFraction: 0.5,
          twsFraction: 0.5,
        );

        expect(result, closeTo(25, 1e-9));
      });

      test('tws-perem (twsFraction 0) → a két low-tws sarok keveréke', () {
        // twsFraction 0 → csak a low-tws oldal súlyoz; twaFraction 0.5.
        final result = bilinearInterpolate(
          lowTwaLowTws: 10,
          lowTwaHighTws: 20,
          highTwaLowTws: 30,
          highTwaHighTws: 40,
          twaFraction: 0.5,
          twsFraction: 0,
        );

        expect(result, closeTo(20, 1e-9));
      });
    });

    group('hiányzó sarkok (üres vödör)', () {
      test('belső pont, egy sarok null → újranormált átlag', () {
        // (0.5,0.5): a megmaradó három sarok egyenlő súllyal (0.25),
        // újranormálva → (20+30+40)/3 = 30.
        final result = bilinearInterpolate(
          lowTwaLowTws: null,
          lowTwaHighTws: 20,
          highTwaLowTws: 30,
          highTwaHighTws: 40,
          twaFraction: 0.5,
          twsFraction: 0.5,
        );

        expect(result, closeTo(30, 1e-9));
      });

      test('a tényleges vödör (súly=1) üres, a többi súlytalan → null', () {
        // (0,0): csak a low-low súlyoz (1), de az null; a többi súlya 0,
        // így a nem-null sarkok együttes súlya 0 → null.
        final result = bilinearInterpolate(
          lowTwaLowTws: null,
          lowTwaHighTws: 20,
          highTwaLowTws: 30,
          highTwaHighTws: 40,
          twaFraction: 0,
          twsFraction: 0,
        );

        expect(result, isNull);
      });

      test('mind a négy sarok null → null', () {
        final result = bilinearInterpolate(
          lowTwaLowTws: null,
          lowTwaHighTws: null,
          highTwaLowTws: null,
          highTwaHighTws: null,
          twaFraction: 0.5,
          twsFraction: 0.5,
        );

        expect(result, isNull);
      });
    });
  });
}
