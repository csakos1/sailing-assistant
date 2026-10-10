import 'package:data/data.dart';
import 'package:domain/domain.dart';

/// A háttér-RaceEngine életciklusát és állapot-streamjét absztraháló varrat
/// (DIP).
///
/// A konkrét `ForegroundTaskEngineHost` egy Android foreground service-t és egy
/// háttér-izolátumot hosztol; a tesztek fake-kel helyettesítik. A stream a
/// `RaceSnapshot`-ot szállítja (ADR 0017 addendum), amit a UI read-only
/// tükörként fogyaszt.
abstract interface class RaceEngineHost {
  /// Elindítja a foreground service-t és a háttér-izolátumot a [race]-szel
  /// (a Race a ready-kézfogásra megy át, A13); `race` nélkül az engine
  /// szabad módban indul (ADR 0054 D1). Visszaadja a `ServiceRequestFailure`
  /// üzenetét, vagy `null`-t, ha a service elindult. A [polar] (ha van) az
  /// init-üzenettel jut a háttér-engine-hez (ADR 0028 Add. 3, A1); `null`
  /// esetén a cél-sebesség mindig `null`.
  Future<String?> start({Race? race, Polar? polar});

  /// Versenycsere a futó engine-ben (ADR 0054 D6): a [race] lesz az engine
  /// versenye, `null` esetén szabad mód. Aktív verseny közben az engine
  /// eldobja a parancsot (ADR 0017 A10).
  void sendRaceCommand(Race? race);

  /// Start parancs az engine-nek (`notStarted → active`) az [at] időponttal.
  void sendStartCommand(DateTime at);

  /// Finish parancs az engine-nek (`active → finished`) az [at] időponttal.
  void sendFinishCommand(DateTime at);

  /// Manuális bója-megkerülés parancs az engine-nek: a hajós kézzel jelzi,
  /// hogy vette a bóját (pontatlan bója-koordinátánál, amikor az auto-
  /// detektor 50 m-es küszöbét sosem éri el). Az engine a saját órájával
  /// bélyegez, ezért nincs `at`.
  void sendRoundMarkCommand();

  /// Leállítja a service-t és a háttér-izolátumot.
  Future<void> stop();

  /// Lezárja a hostot és a snapshot-streamet (provider-eldobáskor).
  Future<void> dispose();

  /// A háttér-izolátum által emittált pillanatképek folyama.
  Stream<RaceSnapshot> get snapshots;
}
