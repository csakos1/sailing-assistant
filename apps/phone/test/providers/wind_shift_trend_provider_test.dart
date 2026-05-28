import 'dart:async';

import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/providers/tick_provider.dart';
import 'package:phone/providers/wind_history_provider.dart';
import 'package:phone/providers/wind_shift_trend_provider.dart';

void main() {
  // Lineáris TWD-trend: percenként 1 minta, twd = 180 + perc. A use case math a
  // domainben fedett; itt a provider-wiringet (history + window + tick-now)
  // verifikáljuk, ezért elég a sampleCount / null viselkedés.
  final epoch = DateTime.utc(2026, 5, 28, 10);

  List<WindObservation> observations(int count) => [
    for (var i = 0; i < count; i++)
      WindObservation(
        twd: Bearing.true_((180 + i).toDouble()),
        timestamp: epoch.add(Duration(minutes: i)),
      ),
  ];

  late StreamController<DateTime> ticks;

  ProviderContainer makeContainer(List<WindObservation> history) {
    ticks = StreamController<DateTime>.broadcast();
    final container = ProviderContainer(
      overrides: [
        tickProvider.overrideWith((ref) => ticks.stream),
        windHistoryProvider.overrideWith(() => _FixedHistory(history)),
      ],
    )..listen(windShiftTrendProvider, (_, _) {});
    addTearDown(ticks.close);
    addTearDown(container.dispose);
    return container;
  }

  Future<void> tick(DateTime at) async {
    ticks.add(at);
    await pumpEventQueue();
  }

  group('windShiftTrendProvider', () {
    test('első tick előtt → null', () {
      final container = makeContainer(observations(12));
      expect(container.read(windShiftTrendProvider), isNull);
    });

    test('kevesebb mint 10 minta az ablakban → null', () async {
      final container = makeContainer(observations(9));
      await tick(epoch.add(const Duration(minutes: 8)));
      expect(container.read(windShiftTrendProvider), isNull);
    });

    test('legalább 10 minta az ablakban → trend (now a tickből)', () async {
      final container = makeContainer(observations(15));
      // now = 14. perc, 10 perces ablak → az 5..14. perc mintái (10 db).
      await tick(epoch.add(const Duration(minutes: 14)));

      final trend = container.read(windShiftTrendProvider);
      expect(trend, isNotNull);
      expect(trend!.sampleCount, greaterThanOrEqualTo(10));
    });

    test('későbbi tick kiviszi az ablakból a mintákat → null', () async {
      final container = makeContainer(observations(15));
      // now = 40. perc, 10 perces ablak → 30..40. perc: nincs ilyen minta.
      await tick(epoch.add(const Duration(minutes: 40)));
      expect(container.read(windShiftTrendProvider), isNull);
    });
  });
}

class _FixedHistory extends WindHistoryNotifier {
  _FixedHistory(this._history);

  final List<WindObservation> _history;

  @override
  List<WindObservation> build() => _history;
}
