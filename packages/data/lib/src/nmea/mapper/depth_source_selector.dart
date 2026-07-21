/// A mélység-forrás választója: eldönti, hogy egy beérkezett mélység-minta
/// emittálható-e.
///
/// A Vulcan a `DBT`-t és a `DPT`-t **egyszerre** szórja, ~1 Hz-en, a `DPT`-t
/// a `DBT` után. Mivel a `BoatStateReducer` last-wins, gate nélkül mindig a
/// `DPT` nyerne — pontosan az a forrás, amit a mérés leváltott (a hamis
/// 2,0 m mintái a 2,5 m-es riasztási küszöb alatt vannak). A selector ezért
/// elnyomja a fallbacket, amíg [primaryHoldWindow]-n belül érkezett
/// elsődleges minta (ADR 0031 Addendum 2, A2-D1).
///
/// A `NmeaToDomainMapper` delegál ide, `bool` + [DateTime] felülettel, hogy
/// a selector se a parser `DecodedSentence` családjától, se a domaintől ne
/// függjön — így önmagában, óra-mock nélkül tesztelhető.
///
/// **Stateful.** Az utolsó elsődleges minta idejét privát mutable mezőben
/// tartja, a stream teljes élettartamára.
class DepthSourceSelector {
  /// Ennyi ideig nyomjuk el a fallback forrást egy elsődleges minta után.
  ///
  /// ~1 Hz-es `DBT` mellett ez négy kihagyott minta tolerálása; a `DBT`
  /// végleges elnémulása után viszont 6 csomón már ~15 m út alatt átvesz a
  /// fallback (ADR 0031 A2-D2). Hard-coded, mint a D3 küszöbei.
  static const Duration primaryHoldWindow = Duration(seconds: 5);

  // Az utolsó elsődleges (DBT) minta app-óra időbélyege; amíg null, sosem
  // volt elsődleges forrás.
  DateTime? _lastPrimaryAt;

  /// Jelzi, hogy a [now]-kor érkezett minta emittálható-e.
  ///
  /// Az elsődleges ([isPrimary]) minta mindig emittálható, és egyben
  /// megnyitja az elnyomási ablakot — ezért van a metódusnak mellékhatása,
  /// ugyanazzal az alkalmaz-és-felelj mintával, mint a `WindAggregator`
  /// apply-metódusainál. A fallback csak akkor emittálható, ha még sosem
  /// volt elsődleges forrás, vagy az utolsó óta letelt a
  /// [primaryHoldWindow].
  bool shouldEmit({required bool isPrimary, required DateTime now}) {
    if (isPrimary) {
      _lastPrimaryAt = now;
      return true;
    }

    final lastPrimaryAt = _lastPrimaryAt;
    if (lastPrimaryAt == null) {
      return true;
    }

    // Visszaugró app-óránál a különbség negatív, így a >= elnyomásra dönt —
    // ez a konzervatív irány, a DBT-elsőbbség marad érvényben.
    return now.difference(lastPrimaryAt) >= primaryHoldWindow;
  }
}
