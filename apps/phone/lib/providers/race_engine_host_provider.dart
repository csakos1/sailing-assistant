import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/engine/foreground_task_engine_host.dart';
import 'package:phone/engine/race_engine_host.dart';

/// A háttér-engine hostját adó provider (keep-alive).
///
/// Klasszikus Riverpod, codegen nélkül. A tesztek `FakeRaceEngineHost`-ra
/// override-olják. A host streamjét a provider eldobásakor lezárjuk.
final raceEngineHostProvider = Provider<RaceEngineHost>((ref) {
  final host = ForegroundTaskEngineHost();
  ref.onDispose(host.dispose);
  return host;
});
