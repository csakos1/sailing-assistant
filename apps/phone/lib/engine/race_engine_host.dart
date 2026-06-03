import 'package:phone/engine/engine_heartbeat.dart';

/// A háttér-RaceEngine életciklusát és állapot-streamjét absztraháló varrat
/// (DIP).
///
/// A konkrét `ForegroundTaskEngineHost` egy Android foreground service-t és egy
/// háttér-izolátumot hosztol; a tesztek `FakeRaceEngineHost`-tal helyettesítik.
/// A scaffold-fázisban a stream még [EngineHeartbeat]-et szállít; a 7-bg-d-ben
/// ez `RaceSnapshot`-ra szélesül.
abstract interface class RaceEngineHost {
  /// Elindítja a foreground service-t és a háttér-izolátumot.
  Future<void> start();

  /// Leállítja a service-t és a háttér-izolátumot.
  Future<void> stop();

  /// Lezárja a hostot és az életjel-streamet (provider-eldobáskor).
  Future<void> dispose();

  /// A háttér-izolátum által emittált életjelek folyama.
  Stream<EngineHeartbeat> get heartbeats;
}
