import 'package:test/test.dart';
import 'package:web_server/src/auth/rate_limiter.dart';

void main() {
  late DateTime now;
  late RateLimiter limiter;

  setUp(() {
    now = DateTime.utc(2026, 10, 7, 9);
    limiter = RateLimiter(
      limit: 3,
      window: const Duration(minutes: 1),
      now: () => now,
    );
  });

  test('allows the limit and then names the wait', () {
    // ARRANGE
    for (var i = 0; i < 3; i++) {
      expect(limiter.tryAcquire('1.2.3.4'), isNull);
      now = now.add(const Duration(seconds: 10));
    }

    // ACT
    final wait = limiter.tryAcquire('1.2.3.4');

    // ASSERT: az első próbálkozás a 0. mp-ben volt, most 30 mp telt el.
    expect(wait, const Duration(seconds: 30));
  });

  test('counts each key on its own', () {
    for (var i = 0; i < 3; i++) {
      limiter.tryAcquire('1.2.3.4');
    }

    expect(limiter.tryAcquire('5.6.7.8'), isNull);
  });

  test('frees a slot when the oldest attempt leaves the window', () {
    for (var i = 0; i < 3; i++) {
      limiter.tryAcquire('1.2.3.4');
    }
    now = now.add(const Duration(minutes: 1));

    expect(limiter.tryAcquire('1.2.3.4'), isNull);
  });

  test('does not count a refused attempt', () {
    for (var i = 0; i < 4; i++) {
      limiter.tryAcquire('1.2.3.4');
    }
    now = now.add(const Duration(minutes: 1));

    expect(limiter.tryAcquire('1.2.3.4'), isNull);
    expect(limiter.tryAcquire('1.2.3.4'), isNull);
    expect(limiter.tryAcquire('1.2.3.4'), isNull);
    expect(limiter.tryAcquire('1.2.3.4'), isNotNull);
  });

  test('keeps working after sweeping many stale keys', () {
    for (var i = 0; i < 5000; i++) {
      limiter.tryAcquire('key-$i');
    }
    now = now.add(const Duration(minutes: 2));

    expect(limiter.tryAcquire('key-1'), isNull);
    expect(limiter.tryAcquire('fresh'), isNull);
  });
}
