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
  /// (a Race a ready-kézfogásra megy át, A13). Visszaadja a
  /// `ServiceRequestFailure` üzenetét, vagy `null`-t, ha a service elindult.
  /// A [polar] (ha van) az init-üzenettel jut a háttér-engine-hez (ADR 0028
  /// Add. 3, A1); `null` esetén a cél-sebesség mindig `null`.
  Future<String?> start(Race race, {Polar? polar});

  /// Start parancs az engine-nek (`notStarted → active`) az [at] időponttal.
  void sendStartCommand(DateTime at);

  /// Finish parancs az engine-nek (`active → finished`) az [at] időponttal.
  void sendFinishCommand(DateTime at);

  /// Manu�lis b�ja-megker�l�s parancs az engine-nek: a haj�s k�zzel jelzi,
  /// hogy vette a b�j�t (pontatlan boja-koordin�t�n�l, amikor az auto-
  /// detektor 50 m-es k�sz�b�t sosem �ri el). Az engine a saj�t �r�j�val
  /// b�lyegez, ez�rt nincs `at`.
  void sendRoundMarkCommand();

  /// Leállítja a service-t és a háttér-izolátumot.
  Future<void> stop();

  /// Lezárja a hostot és a snapshot-streamet (provider-eldobáskor).
  Future<void> dispose();

  /// A háttér-izolátum által emittált pillanatképek folyama.
  Stream<RaceSnapshot> get snapshots;
}
