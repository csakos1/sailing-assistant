import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('DepthAlertState', () {
    test('a default a nyugalmi állapot', () {
      const state = DepthAlertState();

      expect(state.isActive, isFalse);
      expect(state.lowestBuzzedBucket, isNull);
      expect(state.buzzCounter, equals(0));
    });

    test('azonos mezők -> egyenlő', () {
      const a = DepthAlertState(
        isActive: true,
        lowestBuzzedBucket: 2.3,
        buzzCounter: 2,
      );
      const b = DepthAlertState(
        isActive: true,
        lowestBuzzedBucket: 2.3,
        buzzCounter: 2,
      );

      expect(a, equals(b));
    });

    test('eltérő buzzCounter -> nem egyenlő', () {
      const a = DepthAlertState(isActive: true, buzzCounter: 1);
      const b = DepthAlertState(isActive: true, buzzCounter: 2);

      expect(a, isNot(equals(b)));
    });
  });
}
