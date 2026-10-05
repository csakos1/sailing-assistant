import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_web/season_stats/placing_tally.dart';
import 'package:race_archive_api/race_archive_api.dart';

void main() {
  group('tallyPlacings', () {
    test('counts podiums, retirements and the entered races', () {
      // ARRANGE
      const placings = <Placing?>[
        FinishPlace(1),
        FinishPlace(3),
        FinishPlace(1),
        FinishPlace(7),
        Dnf(),
        Dsq(),
        null,
        FinishPlace(2),
      ];

      // ACT
      final tally = tallyPlacings(placings);

      // ASSERT
      expect(tally.firsts, 2);
      expect(tally.seconds, 1);
      expect(tally.thirds, 1);
      expect(tally.podiums, 4);
      expect(tally.dnfs, 1);
      expect(tally.dsqs, 1);
      expect(tally.enteredCount, 7);
      // (1 + 3 + 1 + 7 + 2) / 5 = 2,8
      expect(tally.averagePlace, closeTo(2.8, 1e-9));
    });

    test('has no average without a numeric place', () {
      // ACT
      final tally = tallyPlacings(const [Dnf(), null, Dsq()]);

      // ASSERT
      expect(tally.averagePlace, isNull);
      expect(tally.enteredCount, 2);
      expect(tally.podiums, 0);
    });

    test('is all zero for no races', () {
      // ACT
      final tally = tallyPlacings(const []);

      // ASSERT
      expect(tally.enteredCount, 0);
      expect(tally.podiums, 0);
      expect(tally.averagePlace, isNull);
    });
  });
}
