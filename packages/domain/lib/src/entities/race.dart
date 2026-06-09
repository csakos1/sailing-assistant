import 'package:domain/src/entities/mark.dart';
import 'package:domain/src/entities/race_status.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Egy konkrét vitorlás verseny, amit a hajón élőben futtatunk.
///
/// Identitás-vezérelt entitás: két azonos tartalmú [Race] sem ugyanaz; az
/// [id] dönti el. A [marks] sorrendje a verseny pálya-sorrendje (0. index
/// = első bója).
///
/// A state-trojka ([status], [activeMarkIndex], [startedAt], [finishedAt])
/// konzisztenciáját asserttel őrizzük:
///
/// | status     | activeMarkIndex          | startedAt | finishedAt |
/// |------------|--------------------------|-----------|------------|
/// | notStarted | == 0                     | null      | null       |
/// | active     | 0 ≤ i < marks.length     | nem null  | null       |
/// | finished   | == marks.length          | nem null  | nem null   |
///
/// State-átmenetekhez a `start`, `roundCurrentMark`, `finish` named
/// factory-k állnak rendelkezésre; közvetlen [Race] konstruálás csak teljes
/// state-trojkával (tipikusan perzisztenciából való betöltéskor).
@immutable
class Race extends Equatable {
  /// Egyenes konstruktor. Tipikusan perzisztenciából betöltött Race
  /// rekonstrukciójához. Új verseny létrehozására a [Race.create] factory.
  Race({
    required this.id,
    required this.name,
    required List<Mark> marks,
    required this.status,
    required this.activeMarkIndex,
    this.startedAt,
    this.finishedAt,
  }) : marks = List.unmodifiable(marks),
       assert(id != '', 'A race id-je nem lehet üres.'),
       assert(name != '', 'A race neve nem lehet üres.'),
       assert(
         marks.isNotEmpty,
         'A race-nek legalább egy bóyája kell legyen.',
       ),
       assert(
         _invariantHolds(
           status: status,
           activeMarkIndex: activeMarkIndex,
           marksLength: marks.length,
           startedAt: startedAt,
           finishedAt: finishedAt,
         ),
         'Inkonzisztens state-trojka: status=$status, '
         'activeMarkIndex=$activeMarkIndex, marks.length=${marks.length}, '
         'startedAt=$startedAt, finishedAt=$finishedAt.',
       );

  /// Új race létrehozása `notStarted` állapotban. Az `activeMarkIndex`
  /// nullára áll, időbélyegek üresek. Tipikus belépési pont egy új verseny
  /// felvitelekor.
  factory Race.create({
    required String id,
    required String name,
    required List<Mark> marks,
  }) {
    return Race(
      id: id,
      name: name,
      marks: marks,
      status: RaceStatus.notStarted,
      activeMarkIndex: 0,
    );
  }

  final String id;
  final String name;
  final List<Mark> marks;
  final RaceStatus status;
  final int activeMarkIndex;
  final DateTime? startedAt;
  final DateTime? finishedAt;

  /// Az aktuálisan célzott bóya, vagy `null`, ha a race befejeződött.
  ///
  /// `notStarted` → első bóya (`marks[0]`), `active` →
  /// `marks[activeMarkIndex]`, `finished` → `null` (ekkor
  /// `activeMarkIndex == marks.length`, tartományon kívül). Tisztán
  /// bounds-alapú; a `markPredictionProvider` és a `markRoundingMonitor`
  /// közös, domain-szintű aktív-bója forrása.
  Mark? get activeMarkOrNull =>
      activeMarkIndex < marks.length ? marks[activeMarkIndex] : null;

  /// A következő bóya (a köv. szár fix irányának számításához,
  /// ADR 0021), vagy `null`, ha nincs köv. szár.
  ///
  /// `marks[activeMarkIndex + 1]`, ha az index tartományon belül van;
  /// egyébként `null`. notStarted → `marks[1]` (ha van), active → a
  /// soron következő bóya, az utolsó aktív bóyán és `finished`
  /// állapotban → `null` (nincs köv. szár → a predikció elnémul).
  /// Tisztán bounds-alapú, az `activeMarkOrNull` mintáját követi.
  Mark? get nextMarkOrNull =>
      activeMarkIndex + 1 < marks.length ? marks[activeMarkIndex + 1] : null;

  /// State-átmenet: [RaceStatus.notStarted] → [RaceStatus.active].
  ///
  /// Csak `notStarted` állapotból hívható. Az `activeMarkIndex` 0 marad
  /// (az első bóyára tartunk).
  Race start({required DateTime at}) {
    assert(
      status == RaceStatus.notStarted,
      'Csak notStarted állapotból indítható; jelenleg: $status.',
    );
    return Race(
      id: id,
      name: name,
      marks: marks,
      status: RaceStatus.active,
      activeMarkIndex: activeMarkIndex,
      startedAt: at,
      finishedAt: finishedAt,
    );
  }

  /// Az aktuális bóyát körözöttként megjelöli és lépteti az
  /// `activeMarkIndex`-et.
  ///
  /// Ha ez volt az utolsó bóya, a race `finished` állapotba kerül,
  /// `finishedAt` az [at] értékre áll. Csak `active` állapotból hívható.
  Race roundCurrentMark({required DateTime at}) {
    assert(
      status == RaceStatus.active,
      'roundCurrentMark csak active race-ben hívható; jelenleg: $status.',
    );

    // Új immutable lista a frissített Markkal — csak az aktuális indexet
    // cseréljük.
    final newMarks = [
      for (var i = 0; i < marks.length; i++)
        if (i == activeMarkIndex)
          marks[i].markedAsRounded(at: at)
        else
          marks[i],
    ];

    final wasLast = activeMarkIndex == marks.length - 1;
    return Race(
      id: id,
      name: name,
      marks: newMarks,
      status: wasLast ? RaceStatus.finished : RaceStatus.active,
      activeMarkIndex: activeMarkIndex + 1,
      startedAt: startedAt,
      finishedAt: wasLast ? at : finishedAt,
    );
  }

  /// Explicit `active` → `finished` átmenet az aktuális bója körözése
  /// nélkül. DNF, abort vagy időtúllépés esetére.
  ///
  /// Az `activeMarkIndex`-et `marks.length`-re állítja, hogy a finished
  /// state-trojka invariánsa teljesüljön.
  Race finish({required DateTime at}) {
    assert(
      status == RaceStatus.active,
      'finish csak active race-ben hívható; jelenleg: $status.',
    );
    return Race(
      id: id,
      name: name,
      marks: marks,
      status: RaceStatus.finished,
      activeMarkIndex: marks.length,
      startedAt: startedAt,
      finishedAt: at,
    );
  }

  /// Immutable update. Simple-form: `null` = ne változtass az adott mezőn.
  ///
  /// State-átmenetekhez NE ezt használjuk — azokra ott vannak a named
  /// factory-k (`start`, `roundCurrentMark`, `finish`). A copyWith
  /// felhasználói edit (pl. névmódosítás) szintű frissítésre van.
  Race copyWith({
    String? id,
    String? name,
    List<Mark>? marks,
    RaceStatus? status,
    int? activeMarkIndex,
    DateTime? startedAt,
    DateTime? finishedAt,
  }) {
    return Race(
      id: id ?? this.id,
      name: name ?? this.name,
      marks: marks ?? this.marks,
      status: status ?? this.status,
      activeMarkIndex: activeMarkIndex ?? this.activeMarkIndex,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
    );
  }

  /// State-trojka konzisztencia-ellenőrző. Asserten keresztül hívva csak dev
  /// mode-ban fut. A switch-expression exhaustive a [RaceStatus] enum
  /// felett — új érték hozzáadásakor a fordító itt jelez először.
  static bool _invariantHolds({
    required RaceStatus status,
    required int activeMarkIndex,
    required int marksLength,
    required DateTime? startedAt,
    required DateTime? finishedAt,
  }) {
    return switch (status) {
      RaceStatus.notStarted =>
        activeMarkIndex == 0 && startedAt == null && finishedAt == null,
      RaceStatus.active =>
        activeMarkIndex >= 0 &&
            activeMarkIndex < marksLength &&
            startedAt != null &&
            finishedAt == null,
      RaceStatus.finished =>
        activeMarkIndex == marksLength &&
            startedAt != null &&
            finishedAt != null,
    };
  }

  @override
  List<Object?> get props => [
    id,
    name,
    marks,
    status,
    activeMarkIndex,
    startedAt,
    finishedAt,
  ];

  @override
  bool? get stringify => true;
}
