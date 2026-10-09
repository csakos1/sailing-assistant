import 'package:domain/src/_internal/rolling_median_maximum.dart';
import 'package:test/test.dart';

void main() {
  group('rollingMedianMaximum', () {
    group('short input', () {
      test('empty input -> null', () {
        expect(rollingMedianMaximum(const [], windowSize: 5), isNull);
      });

      test('single value -> that value', () {
        expect(rollingMedianMaximum(const [7], windowSize: 5), 7);
      });

      test('fewer values than the window -> median of all values', () {
        expect(rollingMedianMaximum(const [2, 9, 4], windowSize: 5), 4);
      });

      test('even count -> the lower middle value', () {
        // Given: ket ertek, ebbol az egyik egy tuske.
        expect(rollingMedianMaximum(const [3, 30], windowSize: 5), 3);
      });
    });

    group('spike suppression', () {
      test('drops a one-sample spike', () {
        expect(
          rollingMedianMaximum(const [5, 5, 5, 34, 5, 5, 5], windowSize: 5),
          5,
        );
      });

      test('drops a two-sample spike (the 58. Kekszalag case)', () {
        // Given: 2,6 kn szelcsend, ket mintan 66 kn-os tuske.
        expect(
          rollingMedianMaximum(const [
            2.6,
            2.6,
            2.6,
            66.4,
            66.2,
            2.5,
            2.5,
            2.5,
          ], windowSize: 5),
          2.6,
        );
      });

      test('drops a spike at the very start of the series', () {
        expect(
          rollingMedianMaximum(const [40, 6, 6, 6, 6, 6], windowSize: 5),
          6,
        );
      });

      test('drops a spike at the very end of the series', () {
        expect(
          rollingMedianMaximum(const [6, 6, 6, 6, 6, 40], windowSize: 5),
          6,
        );
      });
    });

    group('real gusts', () {
      test('keeps a three-sample plateau', () {
        expect(
          rollingMedianMaximum(const [8, 8, 15, 15, 15, 8, 8], windowSize: 5),
          15,
        );
      });

      test('keeps the sustained part of a peaked gust', () {
        // Given: 12 -> 14 -> 18 csucsos lokes; a csucs egyetlen minta.
        // Then: a lokes tartos resze (14) marad, a 18-as csucs nem.
        expect(
          rollingMedianMaximum(const [
            8,
            8,
            12,
            14,
            18,
            14,
            12,
            8,
            8,
          ], windowSize: 5),
          14,
        );
      });

      test('returns the maximum of a steady rise', () {
        expect(
          rollingMedianMaximum(const [1, 2, 3, 4, 5, 6, 7], windowSize: 5),
          5,
        );
      });
    });

    group('window size', () {
      test('a window of one returns the raw maximum', () {
        expect(rollingMedianMaximum(const [1, 9, 3], windowSize: 1), 9);
      });

      test('rejects an even window', () {
        expect(
          () => rollingMedianMaximum(const [1, 2], windowSize: 4),
          throwsArgumentError,
        );
      });

      test('rejects a non-positive window', () {
        expect(
          () => rollingMedianMaximum(const [1, 2], windowSize: 0),
          throwsArgumentError,
        );
      });
    });
  });
}
