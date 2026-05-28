import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/providers/clock_provider.dart';

/// 1 Hz recompute-kadencia a compute-réteghez (ADR 0010 D2,
/// ARCHITECTURE.md 8.6).
///
/// Keep-alive: a főképernyő életében folyamatosan jár. A `clockProvider`-seam
/// köré épül, így tesztben egy kontrollált streammel override-olható (a
/// `Stream.periodic` valós idő, nem determinisztikus). Az első emit +1 s-nél
/// jön; addig a `windShiftTrendProvider` / `markPredictionProvider` null.
final tickProvider = StreamProvider<DateTime>((ref) {
  final clock = ref.watch(clockProvider);
  return Stream<DateTime>.periodic(const Duration(seconds: 1), (_) => clock());
});
