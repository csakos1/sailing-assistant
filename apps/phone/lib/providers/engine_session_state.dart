/// A háttér-engine sessionjének állapota (ADR 0054 D5). A korábbi bool
/// session-flag helyett: a próba és az engine futása külön állapot.
sealed class EngineSessionState {
  const EngineSessionState();
}

/// Az engine nem fut, és a gateway-próba sem: háttérben, kézi leállítás
/// után a következő előtérbe kerülésig, vagy egy sikertelen indítás után.
final class EngineStopped extends EngineSessionState {
  /// Leállított állapot.
  const EngineStopped();
}

/// Az app előtérben keresi a hajót: a gateway-próba fut, az engine nem.
final class EngineProbing extends EngineSessionState {
  /// Próbáló állapot.
  const EngineProbing();
}

/// Az engine fut (foreground service + háttér-izolátum).
final class EngineRunning extends EngineSessionState {
  /// Futó állapot; a [cause] dönti el, milyen versennyel indul.
  const EngineRunning({required this.cause});

  /// Mi indította az engine-t.
  final EngineStartCause cause;
}

/// Az engine indításának oka; a kezdő versenyt határozza meg.
enum EngineStartCause {
  /// A próba megtalálta a hajót: szabad mód, kivéve egy folyamatban lévő
  /// (`active`) versenyt, aminek a legutóbbi felvétele friss
  /// (`IsRaceResumable`); az app-újraindítás után folytatódik.
  gatewayFound,

  /// A felhasználó indította („Élő nézet" vagy „Rajt"): a kiválasztott
  /// verseny megy át.
  user,

  /// Az engine már futott (pl. az appot a feladatkezelőből lesöpörték, a
  /// háttér-service túlélte): az app csatlakozik hozzá, nem indítja újra.
  adopted,
}
