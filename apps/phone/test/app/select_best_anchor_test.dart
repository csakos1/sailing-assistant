import 'package:flutter_test/flutter_test.dart';
import 'package:phone/app/true_time.dart';

void main() {
  group('selectBestAnchorUtc', () {
    test('egyetlen minta → fixUtc - sampleElapsed + burstElapsed', () {
      // ARRANGE
      final samples = <GnssSample>[
        (
          fixUtc: DateTime.utc(2026, 6, 6, 11, 19),
          sampleElapsed: const Duration(milliseconds: 300),
        ),
      ];

      // ACT — a burst-vég ugyanaz, mint a minta kora → vissza a fixUtc
      final result = selectBestAnchorUtc(
        samples,
        const Duration(milliseconds: 300),
      );

      // ASSERT
      expect(result, DateTime.utc(2026, 6, 6, 11, 19));
    });

    test('a max offszetű (min-késésű) mintát választja, nem a legkésőbbit', () {
      // ARRANGE — B később, nagyobb fixUtc-vel, de nagyobb késéssel:
      //   A offszet = 11:19:00.000 - 0.100 = 11:18:59.900
      //   B offszet = 11:19:01.000 - 1.200 = 11:18:59.800  (kisebb → elvetve)
      final samples = <GnssSample>[
        (
          fixUtc: DateTime.utc(2026, 6, 6, 11, 19),
          sampleElapsed: const Duration(milliseconds: 100),
        ),
        (
          fixUtc: DateTime.utc(2026, 6, 6, 11, 19, 1),
          sampleElapsed: const Duration(milliseconds: 1200),
        ),
      ];

      // ACT — burst-vég 1.500 s
      final result = selectBestAnchorUtc(
        samples,
        const Duration(milliseconds: 1500),
      );

      // ASSERT — max offszet (A) + burst-vég: 11:18:59.900 + 1.500
      expect(result, DateTime.utc(2026, 6, 6, 11, 19, 1, 400));
    });

    test('a sorrend nem számít (kommutatív max)', () {
      final s1 = (
        fixUtc: DateTime.utc(2026, 6, 6, 11, 19),
        sampleElapsed: const Duration(milliseconds: 100),
      );
      final s2 = (
        fixUtc: DateTime.utc(2026, 6, 6, 11, 19, 1),
        sampleElapsed: const Duration(milliseconds: 1200),
      );
      const burst = Duration(milliseconds: 1500);

      expect(
        selectBestAnchorUtc(<GnssSample>[s1, s2], burst),
        selectBestAnchorUtc(<GnssSample>[s2, s1], burst),
      );
    });

    test('az eredmény UTC marad', () {
      final result = selectBestAnchorUtc(
        <GnssSample>[
          (fixUtc: DateTime.utc(2026, 6, 6, 11), sampleElapsed: Duration.zero),
        ],
        Duration.zero,
      );
      expect(result.isUtc, isTrue);
    });
  });
}
