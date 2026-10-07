import 'package:test/test.dart';
import 'package:web_server/src/auth/fallback_backoff.dart';

void main() {
  late DateTime now;
  late FallbackBackoff backoff;

  setUp(() {
    now = DateTime.utc(2026, 10, 7, 9);
    backoff = FallbackBackoff(now: () => now);
  });

  // Egymás után [times] hibás próbálkozás, mindegyik a saját foglalásával.
  void failTimes(int times) {
    for (var i = 0; i < times; i++) {
      expect(backoff.tryBegin(), isNull);
      backoff.end(isSuccess: false);
    }
  }

  test('lets four failures pass without waiting', () {
    failTimes(4);

    expect(backoff.remainingWait(), isNull);
  });

  test('blocks from the fifth failure, doubling up to one hour', () {
    final waits = <Duration?>[];
    for (var failure = 1; failure <= 12; failure++) {
      final wait = backoff.remainingWait();
      if (wait != null) now = now.add(wait);
      expect(backoff.tryBegin(), isNull);
      backoff.end(isSuccess: false);
      waits.add(backoff.remainingWait());
    }

    expect(waits, [
      null,
      null,
      null,
      null,
      const Duration(minutes: 1),
      const Duration(minutes: 2),
      const Duration(minutes: 4),
      const Duration(minutes: 8),
      const Duration(minutes: 16),
      const Duration(minutes: 32),
      const Duration(hours: 1),
      const Duration(hours: 1),
    ]);
  });

  test('refuses an attempt while blocked, even the right one', () {
    failTimes(5);

    expect(backoff.tryBegin(), const Duration(minutes: 1));
  });

  test('ends the wait when the time is up and resets on success', () {
    failTimes(5);
    now = now.add(const Duration(minutes: 1));

    expect(backoff.tryBegin(), isNull);
    backoff.end(isSuccess: true);

    failTimes(4);
    expect(backoff.remainingWait(), isNull);
  });

  test('never runs more attempts than the failures still allowed', () {
    failTimes(3);

    final started = [for (var i = 0; i < 4; i++) backoff.tryBegin()];

    expect(started, [
      null,
      null,
      const Duration(seconds: 1),
      const Duration(seconds: 1),
    ]);
  });

  test('lets one attempt run after the wait, not a burst', () {
    failTimes(5);
    now = now.add(const Duration(minutes: 1));

    final first = backoff.tryBegin();
    final second = backoff.tryBegin();

    expect(first, isNull);
    expect(second, const Duration(seconds: 1));
  });
}
