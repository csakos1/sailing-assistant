import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_web/season_stats/placing_order.dart';
import 'package:race_archive_api/race_archive_api.dart';

void main() {
  group('betterPlacing', () {
    test('takes the smaller of two places', () {
      expect(
        betterPlacing(const FinishPlace(12), const FinishPlace(9)),
        const FinishPlace(9),
      );
    });

    test('prefers a place over a retirement or disqualification', () {
      expect(
        betterPlacing(const Dnf(), const FinishPlace(14)),
        const FinishPlace(14),
      );
      expect(
        betterPlacing(const FinishPlace(20), const Dsq()),
        const FinishPlace(20),
      );
    });

    test('prefers a retirement over a disqualification', () {
      expect(betterPlacing(const Dsq(), const Dnf()), const Dnf());
    });

    test('falls back to the given one when the other is missing', () {
      expect(betterPlacing(null, const FinishPlace(2)), const FinishPlace(2));
      expect(betterPlacing(const Dnf(), null), const Dnf());
      expect(betterPlacing(null, null), isNull);
    });
  });
}
