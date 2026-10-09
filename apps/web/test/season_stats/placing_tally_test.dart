import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_web/season_stats/medal.dart';
import 'package:foretack_web/season_stats/placing_tally.dart';
import 'package:race_archive_api/race_archive_api.dart';

void main() {
  group('tallyPlacings', () {
    test('counts the medals and orders the rest', () {
      // ARRANGE
      const placings = <Placing?>[
        FinishPlace(1),
        Dsq(),
        FinishPlace(6),
        FinishPlace(3),
        null,
        Dnf(),
        FinishPlace(1),
        FinishPlace(4),
        FinishPlace(2),
      ];

      // ACT
      final tally = tallyPlacings(placings);

      // ASSERT
      expect(tally.firsts, 2);
      expect(tally.seconds, 1);
      expect(tally.thirds, 1);
      expect(tally.podiums, 4);
      expect(tally.countOf(Medal.gold), 2);
      expect(tally.countOf(Medal.bronze), 1);
      // a szamok novekvo sorrendben, utana DNF, majd DSQ
      expect(tally.offPodium, const [
        FinishPlace(4),
        FinishPlace(6),
        Dnf(),
        Dsq(),
      ]);
    });

    test('is empty for no placings', () {
      // ACT
      final tally = tallyPlacings(const [null, null]);

      // ASSERT
      expect(tally.podiums, 0);
      expect(tally.offPodium, isEmpty);
    });
  });
}
