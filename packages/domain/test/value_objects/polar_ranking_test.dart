import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('PolarRanking', () {
    final ranking = PolarRanking(const {'a': 1, 'b': 2});

    test('gives the rank of a ranked race', () {
      expect(ranking.rankOf('b'), 2);
      expect(ranking.rankedCount, 2);
    });

    test('gives nothing for an unranked race', () {
      expect(ranking.rankOf('nincs'), isNull);
    });

    test('cannot be changed from outside', () {
      expect(() => ranking.ranks['c'] = 3, throwsUnsupportedError);
    });
  });
}
