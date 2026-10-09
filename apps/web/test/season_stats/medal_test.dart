import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_web/season_stats/medal.dart';
import 'package:race_archive_api/race_archive_api.dart';

void main() {
  group('Medal.of', () {
    test('gives a medal for the podium places', () {
      expect(Medal.of(const FinishPlace(1)), Medal.gold);
      expect(Medal.of(const FinishPlace(2)), Medal.silver);
      expect(Medal.of(const FinishPlace(3)), Medal.bronze);
    });

    test('gives nothing off the podium', () {
      expect(Medal.of(const FinishPlace(4)), isNull);
      expect(Medal.of(const Dnf()), isNull);
      expect(Medal.of(const Dsq()), isNull);
      expect(Medal.of(null), isNull);
    });
  });
}
