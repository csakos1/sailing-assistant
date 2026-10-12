import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';
import 'package:phone/providers/engine_session_state.dart';

/// A szabad mód (34a) kapcsolat-állapota a csík pontjához, szövegéhez és a
/// rács tartalmához (`phone-ui-v1.md` §6, ADR 0056 U3).
///
/// A leképezés a sáv Műszerek-cellájáéval (`instrumentsTabStatusOf`) azonos
/// forrásokból és azonos módon dönt, hogy a sáv éle és a csík pontja sose
/// mondjon mást; a csík csak a leállított és a megszakadt állapotot bontja
/// szét, amit a sáv egyformán „nincs kapcsolat"-ként mutat.
///
/// A paraméter nélküli állapotok `const` példányok, így az egyenlőségük a
/// kanonikus példányból adódik; a [FreeModeLost] az adat korát is veti össze.
sealed class FreeModeLink {
  const FreeModeLink();
}

/// A próba keresi a hajót, vagy az engine a session első adata előtt
/// kapcsolódik (34a-1).
final class FreeModeSearching extends FreeModeLink {
  /// Keresés.
  const FreeModeSearching();
}

/// Az engine kapcsolódva van, élő adat jön (34a-2B).
final class FreeModeLive extends FreeModeLink {
  /// Élő kapcsolat.
  const FreeModeLive();
}

/// Az engine fut, de a hajóval megszakadt a kapcsolat (34a-3): az utolsó
/// értékek tompán maradnak. Az újrakapcsolódás alatt is ez marad.
@immutable
final class FreeModeLost extends FreeModeLink {
  /// Megszakadt kapcsolat a [dataAge] korú utolsó adattal.
  const FreeModeLost({this.dataAge});

  /// Az utolsó adat kora; `null`, ha a session alatt még nem jött adat.
  final Duration? dataAge;

  @override
  bool operator ==(Object other) =>
      other is FreeModeLost && other.dataAge == dataAge;

  @override
  int get hashCode => Object.hash(FreeModeLost, dataAge);

  @override
  String toString() => 'FreeModeLost($dataAge)';
}

/// Az engine áll: kézi „Leállítás" után, háttérben, vagy egy sikertelen
/// indítás után. A keresés a következő előtérbe kerüléskor indul újra
/// (ADR 0054 D5).
final class FreeModeStopped extends FreeModeLink {
  /// Leállított állapot.
  const FreeModeStopped();
}

/// A szabad mód kapcsolat-állapota a [session], az engine [connection]-je,
/// az utolsó adat ideje ([lastDataAt]) és a jelen ([now]) alapján.
///
/// A [lastDataAt] `null`, ha a session alatt még nem jött NMEA-esemény; a
/// [now] `null` az első tick előtt. Bármelyik hiányában a kor ismeretlen. Az
/// órák eltérése miatti negatív kor nullára vágódik.
///
/// A futó engine kapcsolata újrapróbálkozás közben `Connecting` és
/// `ConnectionError` között vált (minden próba előtt `Connecting`), sosem
/// `Disconnected`. Ezért a `Connecting` csak a session első adata előtt
/// keresés; utána megszakadt kapcsolat, különben a csík és a rács pár
/// másodpercenként villogna.
FreeModeLink freeModeLinkOf({
  required EngineSessionState session,
  required ConnectionStatus connection,
  required DateTime? lastDataAt,
  required DateTime? now,
}) => switch (session) {
  EngineStopped() => const FreeModeStopped(),
  EngineProbing() => const FreeModeSearching(),
  EngineRunning() => switch (connection) {
    Connected() => const FreeModeLive(),
    Connecting() when lastDataAt == null => const FreeModeSearching(),
    Connecting() || Disconnected() || ConnectionError() => FreeModeLost(
      dataAge: _ageOf(lastDataAt, now),
    ),
  },
};

Duration? _ageOf(DateTime? lastDataAt, DateTime? now) {
  if (lastDataAt == null || now == null) return null;
  final age = now.difference(lastDataAt);
  return age.isNegative ? Duration.zero : age;
}
