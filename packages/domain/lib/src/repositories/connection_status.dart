/// A `NmeaStream` kapcsolat-állapota.
///
/// Sealed, hogy a hiba-ág üzenetet hordozhasson a warning-rendszernek;
/// a `RaceStatus` sealed mintáját követi (ARCHITECTURE.md 5.4). Enum ezt
/// payload nélkül nem tudná.
sealed class ConnectionStatus {
  /// A variánsok payload nélküli singletonok (kivéve [ConnectionError]),
  /// ezért a base ctor const.
  const ConnectionStatus();
}

/// Aktív, adatot kapó kapcsolat.
final class Connected extends ConnectionStatus {
  /// Aktív kapcsolat-állapot.
  const Connected();
}

/// Csatlakozás folyamatban (kezdeti vagy újrapróbálkozás).
final class Connecting extends ConnectionStatus {
  /// Folyamatban lévő csatlakozás állapota.
  const Connecting();
}

/// Nincs kapcsolat (még nem indult, vagy szándékosan lekapcsolt).
final class Disconnected extends ConnectionStatus {
  /// Lekapcsolt állapot.
  const Disconnected();
}

/// Hibás kapcsolat — a [message] ember-olvasható ok a warning-rendszernek.
///
/// A nyers `dart:io` kivételt a data réteg fordítja szöveggé, hogy a
/// domain platform-független maradjon.
final class ConnectionError extends ConnectionStatus {
  /// Hibás állapot a [message] indoklással.
  const ConnectionError(this.message);

  /// Ember-olvasható hibaüzenet (a data réteg fordítja le).
  final String message;
}
