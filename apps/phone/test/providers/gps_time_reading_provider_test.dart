import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/app/true_time.dart';
import 'package:phone/providers/gps_time_reading_provider.dart';
import 'package:phone/providers/true_time_provider.dart';

void main() {
  group('gpsTimeReadingProvider', () {
    test('a trueTimeProvider olvasatát emittálja', () async {
      // Arrange — fix gnss olvasat a callable mögött
      final reading = TrueTimeReading(
        utc: DateTime.utc(2026, 6, 6, 11, 19, 2),
        source: TrueTimeSource.gnss,
      );
      final container = ProviderContainer(
        overrides: [trueTimeProvider.overrideWithValue(() => reading)],
      );
      addTearDown(container.dispose);
      final sub = container.listen(gpsTimeReadingProvider, (_, _) {});
      addTearDown(sub.close);

      // Act — a kezdeti emit propagálódjon a streamen
      await Future<void>.delayed(Duration.zero);
      final emitted = container.read(gpsTimeReadingProvider).value;

      // Assert
      expect(emitted, reading);
    });
  });
}
