import 'package:domain/src/entities/race.dart';
import 'package:domain/src/entities/race_status.dart';
import 'package:domain/src/use_cases/is_race_resumable.dart';
import 'package:domain/src/value_objects/instruments_race_choice.dart';
import 'package:meta/meta.dart';

/// Egy UTC pillanat helyi (falióra szerinti) alakja.
///
/// Élesben `(instant) => instant.toLocal()`; tesztben egy rögzített vagy
/// DST-t szimuláló eltolás, hogy az éjfél- és időzóna-esetek ne a teszt
/// gép időzónájától függjenek. A visszaadott értékből csak az év, a hónap
/// és a nap számít.
typedef LocalWallClock = DateTime Function(DateTime instant);

/// Pure use case: melyik verseny menjen a Műszerek fülre és az engine-be
/// (ADR 0055 D5).
///
/// A sorrend:
///
/// 1. a folytatható `active` verseny ([IsRaceResumable]); egy régóta nem
///    rögzítő aktív verseny (pl. elfelejtett „Cél") nem nyer;
/// 2. a helyi idő szerint **mai**, `notStarted`, tervezett rajtidős
///    versenyek közül, amelyek a visszamenőleges ablakon belül vannak
///    (`now < scheduledStartAt + lateStartWindow`): a mai kézi választás,
///    különben a legkorábbi rajtidejű (egyezésnél a lista sorrendje);
/// 3. különben `null`: szabad mód.
///
/// Dátum nélküli versenyt sosem választ. A „mai" a rajtidő helyi napja: egy
/// 23:30-as rajt éjfél után már nem mai, akkor sem, ha az ablakon belül
/// van.
@immutable
class SelectInstrumentsRace {
  /// Állapotmentes use case; az ablak alapértéke [defaultLateStartWindow].
  const SelectInstrumentsRace({
    this.lateStartWindow = defaultLateStartWindow,
    this.isRaceResumable = const IsRaceResumable(),
  });

  /// A visszamenőleges rajt ablaka (ADR 0055 D7): a tervezett rajtidő után
  /// ennyi ideig választódik ki magától egy el nem indult verseny.
  static const Duration defaultLateStartWindow = Duration(hours: 3);

  /// A tervezett rajt utáni ablak, amelyen belül a verseny még kiválasztható.
  final Duration lateStartWindow;

  /// Az aktív verseny folytathatóságának szabálya (ADR 0054 E3).
  final IsRaceResumable isRaceResumable;

  /// A kiválasztott verseny, vagy `null` (szabad mód).
  ///
  /// A [now] a true time UTC-ben. Az [activeRaceLastRecordedAt] a
  /// [latestActiveRace] által adott verseny legutóbbi rögzített
  /// pillanatképének ideje (`null`: nincs felvétel, vagy nincs aktív
  /// verseny). A [manualChoice] csak a helyi mai napon és csak egy jelölt
  /// versenyre érvényes.
  Race? call({
    required List<Race> races,
    required DateTime now,
    required LocalWallClock toLocal,
    required DateTime? activeRaceLastRecordedAt,
    InstrumentsRaceChoice? manualChoice,
  }) {
    final active = latestActiveRace(races);
    if (active != null &&
        isRaceResumable(
          race: active,
          lastRecordedAt: activeRaceLastRecordedAt,
          now: now,
        )) {
      return active;
    }
    final today = toLocal(now);
    bool isCandidate(Race race) =>
        _isScheduledCandidate(race, now: now, today: today, toLocal: toLocal);
    final candidates = races.where(isCandidate).toList();
    if (candidates.isEmpty) return null;
    return _manuallyChosen(candidates, manualChoice, today) ??
        _earliestScheduled(candidates);
  }

  bool _isScheduledCandidate(
    Race race, {
    required DateTime now,
    required DateTime today,
    required LocalWallClock toLocal,
  }) {
    final scheduledStartAt = race.scheduledStartAt;
    if (race.status != RaceStatus.notStarted || scheduledStartAt == null) {
      return false;
    }
    return _isSameDay(toLocal(scheduledStartAt), today) &&
        now.isBefore(scheduledStartAt.add(lateStartWindow));
  }

  /// Az az aktív verseny, amelyikről a kiválasztás dönt, vagy `null`.
  ///
  /// Egyszerre egy aktív verseny a normális; ha mégis több van, a
  /// legkésőbb indult számít (a többi egy félbehagyott, régi verseny). A
  /// hívó ennek a versenynek a legutóbbi felvételét adja át
  /// `activeRaceLastRecordedAt`-ként.
  static Race? latestActiveRace(List<Race> races) {
    Race? latest;
    for (final race in races) {
      if (race.status != RaceStatus.active) continue;
      // Az `active` invariánsa szerint a `startedAt` nem null; a null-őr
      // csak egy hibás, kézzel épített Race ellen véd.
      final startedAt = race.startedAt;
      final latestStartedAt = latest?.startedAt;
      if (latest == null ||
          (startedAt != null &&
              latestStartedAt != null &&
              startedAt.isAfter(latestStartedAt))) {
        latest = race;
      }
    }
    return latest;
  }

  static Race? _manuallyChosen(
    List<Race> candidates,
    InstrumentsRaceChoice? choice,
    DateTime today,
  ) {
    if (choice == null || !_isSameDay(choice.chosenOnLocalDay, today)) {
      return null;
    }
    for (final race in candidates) {
      if (race.id == choice.raceId) return race;
    }
    return null;
  }

  static Race _earliestScheduled(List<Race> candidates) {
    var earliest = candidates.first;
    for (final race in candidates.skip(1)) {
      // A jelöltek mind rajtidősek (_isScheduledCandidate), ezért a `!`
      // itt nem dobhat.
      if (race.scheduledStartAt!.isBefore(earliest.scheduledStartAt!)) {
        earliest = race;
      }
    }
    return earliest;
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
