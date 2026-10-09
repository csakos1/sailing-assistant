import 'package:flutter/foundation.dart';

/// A fül bezárására figyelmeztető feltételek gyűjtője (ADR 0048
/// Addendum 4 K24).
///
/// A képernyők feltételt jegyeznek be (mentetlen szerkesztés, futó
/// feltöltés). A böngésző `beforeunload` figyelője a bezárás pillanatában
/// kérdezi meg, kell-e figyelmeztetni. Pure: a böngészőhöz a
/// `leaveWarningProvider` köti.
class LeaveWarningRegistry {
  final List<_Hold> _holds = [];

  /// Bejegyzi a [shouldWarn] feltételt; a visszaadott függvény leveszi.
  VoidCallback hold(bool Function() shouldWarn) {
    // Saját objektum, nem maga a függvény: két egyforma tear-off
    // egyenlő, és a levétel rossz bejegyzést vihetne el.
    final hold = _Hold(shouldWarn);
    _holds.add(hold);
    return () => _holds.remove(hold);
  }

  /// Igaz-e most bármelyik bejegyzett feltétel.
  bool get shouldWarn => _holds.any((hold) => hold.shouldWarn());
}

final class _Hold {
  _Hold(this.shouldWarn);

  final bool Function() shouldWarn;
}
