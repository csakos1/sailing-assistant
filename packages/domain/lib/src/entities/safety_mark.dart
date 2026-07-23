import 'package:domain/src/entities/cardinal_direction.dart';
import 'package:domain/src/value_objects/coordinate.dart';
import 'package:domain/src/value_objects/distance.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Állandó navigációs jelölők sealed hierarchiája (ADR 0037,
/// ARCHITECTURE.md 5.2).
///
/// A tó fix objektumai: kardinális bóják, meteorológiai platformok,
/// védett területek és gázlót jelző bóják. Fordítási idejű katalógusból
/// jönnek (`SafetyMarkRepository`), nem szerkeszthetők, és semmilyen
/// kapcsolatuk nincs a verseny pályájával.
///
/// **Miért nem `Mark`.** A `Mark` sorszámozott, egy `Race` pályájában
/// él, megkerülendő, felhasználó által szerkeszthető (ADR 0029), és élő
/// gépezetet hajt (`MarkRoundingDetector`, `activeMarkIndex`, next-leg
/// bearing). Egy kardinálisnak ezekből egyik sincs. Közös típusban a
/// `sequence` a példányok felére értelmetlen lenne (LSP-törés), és
/// minden fogyasztónak szűrnie kellene — az az egy elfelejtett szűrő
/// vízen jelentkezne, egy kardinálissal mint predikció-célponttal.
///
/// **Miért sealed.** A megjelenítés kimerítő `switch`-csel rendel jelet
/// a fajtákhoz (a `Warning` mintája), így egy ötödik fajta felvétele
/// fordítási hibaként mutatja meg az összes rajzolási pontot.
///
/// Az egyenlőség `Equatable`-alapú, tehát a `runtimeType` is beleszámít:
/// két különböző fajta azonos pozícióval és címkével **nem** egyenlő.
@immutable
sealed class SafetyMark extends Equatable {
  /// Bázis-konstruktor. A címke nem lehet üres string — a jelölők
  /// katalógusból jönnek, ahol az üres címke programozói hiba.
  const SafetyMark({
    required this.position,
    required this.label,
  }) : assert(label != '', 'A jelölő címkéje nem lehet üres.');

  /// A jelölő földrajzi pozíciója. Területnél a terület középpontja.
  final Coordinate position;

  /// Ember-olvasható azonosító (pl. `'Siófok'`). A megjelenítés
  /// fajtánként dönti el, kiírja-e: a kardinálisok jele önmagában
  /// olvasható, a fix építmények neve viszont érdemi információ.
  final String label;

  @override
  bool? get stringify => true;
}

/// Kardinális bója: a biztonságos víz irányát jelöli a veszélyhez
/// képest, csatorna szélén vagy zátony mellett.
final class CardinalMark extends SafetyMark {
  /// Kardinális bója a megadott fajtával.
  const CardinalMark({
    required super.position,
    required super.label,
    required this.direction,
  });

  /// A kardinális fajtája. Ez határozza meg a topjelet és a színsávot,
  /// és azt, merre kell elhaladni mellette.
  final CardinalDirection direction;

  @override
  List<Object?> get props => [position, label, direction];
}

/// Fix vízi építmény (meteorológiai platform, cölöp): állandó akadály,
/// aminek nincs kardinális iránya és nincs biztonságos oldala — ki kell
/// kerülni.
final class FixedStructure extends SafetyMark {
  /// Fix építmény a megadott pozíción.
  const FixedStructure({required super.position, required super.label});

  @override
  List<Object?> get props => [position, label];
}

/// Korlátozott terület, például védett ívóhely.
///
/// Négyzet alakú, a `position` a **középpontja**. A forrásadat is így
/// érkezik (középpont + oldalhossz), ezért poligon-pontlista helyett ez
/// a tárolás — nem veszít információt, és nem talál ki sarokpontokat.
final class RestrictedArea extends SafetyMark {
  /// Négyzet alakú terület a középpontjával és oldalhosszával.
  const RestrictedArea({
    required super.position,
    required super.label,
    required this.sideLength,
  });

  /// A négyzet oldalhossza. A terület a középpont köré szimmetrikus,
  /// tehát minden irányban ennek a fele nyúlik el.
  final Distance sideLength;

  @override
  List<Object?> get props => [position, label, sideLength];
}

/// Gázlót jelző bója: a part felé sekélyedő vizet határolja.
///
/// Ezeket a rendezőség helyenként csak egy-egy versenyre teszi ki, de a
/// jelzett gázló **állandó**, ezért a katalógus szezontól függetlenül
/// tartalmazza őket (ADR 0037 D18). A bója szezonális, a veszély nem.
final class ShallowWaterMark extends SafetyMark {
  /// Gázlót jelző bója a megadott pozíción.
  const ShallowWaterMark({required super.position, required super.label});

  @override
  List<Object?> get props => [position, label];
}
