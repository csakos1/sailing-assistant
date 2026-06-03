import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  const reducer = WindHistoryReducer();
  const twd = Bearing(degrees: 200, reference: BearingReference.trueNorth);

  WindObservation obsAt(DateTime t) => WindObservation(twd: twd, timestamp: t);

  group('append', () {
    test('üres történethez fűzve egyelemű listát ad', () {
      final t = DateTime.utc(2025, 6, 1, 10);
      final result = reducer(const <WindObservation>[], obsAt(t));
      expect(result, [obsAt(t)]);
    });

    test('a sorrend megmarad: a régi elöl, az új hátul', () {
      final t0 = DateTime.utc(2025, 6, 1, 10);
      final t1 = DateTime.utc(2025, 6, 1, 10, 1);
      final result = reducer([obsAt(t0)], obsAt(t1));
      expect(result.map((o) => o.timestamp).toList(), [t0, t1]);
    });

    test('a bemeneti listát nem mutálja', () {
      final t0 = DateTime.utc(2025, 6, 1, 10);
      final t1 = DateTime.utc(2025, 6, 1, 10, 1);
      final history = [obsAt(t0)];
      reducer(history, obsAt(t1));
      expect(history, [obsAt(t0)]);
    });
  });

  group('idő-nyírás', () {
    test('a default 30 perces ablaknál régebbieket levágja', () {
      final older = DateTime.utc(2025, 6, 1, 10);
      final newest = DateTime.utc(2025, 6, 1, 10, 31);
      final result = reducer([obsAt(older)], obsAt(newest));
      expect(result.map((o) => o.timestamp).toList(), [newest]);
    });

    test('az ablakon belüli observation megmarad', () {
      final recent = DateTime.utc(2025, 6, 1, 10);
      final newest = DateTime.utc(2025, 6, 1, 10, 29);
      final result = reducer([obsAt(recent)], obsAt(newest));
      expect(result.map((o) => o.timestamp).toList(), [recent, newest]);
    });

    test('a cutoff szigorú: a pontosan az ablak-határon lévő kiesik', () {
      final newest = DateTime.utc(2025, 6, 1, 10, 30);
      final onCutoff = DateTime.utc(2025, 6, 1, 10); // newest - 30 perc
      final result = reducer([obsAt(onCutoff)], obsAt(newest));
      expect(result.map((o) => o.timestamp).toList(), [newest]);
    });

    test('egyedi ablak-paraméter felülírja a defaultot', () {
      final older = DateTime.utc(2025, 6, 1, 10);
      final newest = DateTime.utc(2025, 6, 1, 10, 6);
      final result = reducer(
        [obsAt(older)],
        obsAt(newest),
        window: const Duration(minutes: 5),
      );
      expect(result.map((o) => o.timestamp).toList(), [newest]);
    });
  });
}
