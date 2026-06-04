import 'package:data/data.dart';

/// A háttér-RaceEngine életciklusát és állapot-streamjét absztraháló varrat
/// (DIP).
///
/// A konkrét `ForegroundTaskEngineHost` egy Android foreground service-t és egy
/// háttér-izolátumot hosztol; a tesztek fake-kel helyettesítik. A stream a
/// `RaceSnapshot`-ot szállítja (ADR 0017 addendum), amit a UI read-only
/// tükörként fogyaszt.
abstract interface class RaceEngineHost {
  /// Elindítja a foreground service-t és a háttér-izolátumot.
  Future<void> start();

  /// Leállítja a service-t és a háttér-izolátumot.
  Future<void> stop();

  /// Lezárja a hostot és a snapshot-streamet (provider-eldobáskor).
  Future<void> dispose();

  /// A háttér-izolátum által emittált pillanatképek folyama.
  Stream<RaceSnapshot> get snapshots;
}
