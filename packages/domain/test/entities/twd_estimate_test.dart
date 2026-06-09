import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('TwdEstimate', () {
    test('unavailable factory has a null twd', () {
      const estimate = TwdEstimate.unavailable();
      expect(estimate.twd, isNull);
      expect(estimate.quality, TwdQuality.unavailable);
    });

    test('live estimate carries a twd', () {
      final estimate = TwdEstimate(
        twd: const Bearing.true_(250),
        quality: TwdQuality.live,
      );
      expect(estimate.twd, const Bearing.true_(250));
      expect(estimate.quality, TwdQuality.live);
    });

    test('throws when live or held is constructed without a twd', () {
      // Az invariáns: live/held → twd != null.
      expect(
        () => TwdEstimate(twd: null, quality: TwdQuality.held),
        throwsA(isA<AssertionError>()),
      );
    });

    test('throws when unavailable is constructed with a twd', () {
      expect(
        () => TwdEstimate(
          twd: const Bearing.true_(250),
          quality: TwdQuality.unavailable,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
