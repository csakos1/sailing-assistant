import 'package:equatable/equatable.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:web_server/src/legacy/legacy_race.dart';
import 'package:web_server/src/legacy/legacy_row_rejection.dart';
import 'package:web_server/src/legacy/telemetry_candidate.dart';
import 'package:web_server/src/web_db/manual_race_record.dart';

/// Az import tervének egy tétele (ADR 0048 Addendum 6 M1).
///
/// Sealed, hogy a kiírás és az alkalmazás kimerítő `switch`-csel kezelje
/// minden esetet.
sealed class LegacyPlanItem extends Equatable {
  const LegacyPlanItem();

  /// Az Excel-sor száma, amelyből a tétel jön.
  int get rowNumber;
}

/// Egy Excel-sor eredménye egy telemetriás versenyre kerül.
final class PlannedResult extends LegacyPlanItem {
  /// A [race] sor [result] eredménye a [target] versenyre.
  const PlannedResult({
    required this.race,
    required this.target,
    required this.result,
    required this.isExplicit,
    this.splitDay,
  });

  /// A forrás Excel-sor.
  final LegacyRace race;

  /// A telemetriás verseny.
  final TelemetryCandidate target;

  /// Az írandó eredmény (kétnapos sornál a nap része, M5).
  final RaceResultInput result;

  /// Igaz, ha a párosítást a `--match` kapcsoló adta.
  final bool isExplicit;

  /// Kétnapos sornál a nap (1 vagy 2), különben `null`.
  final int? splitDay;

  @override
  int get rowNumber => race.rowNumber;

  @override
  List<Object?> get props => [race, target, result, isExplicit, splitDay];
}

/// Egy Excel-sorból kézi verseny lesz.
final class PlannedManualRace extends LegacyPlanItem {
  /// A [race] sor kézi versenyként, az [id] azonosítóval.
  const PlannedManualRace({
    required this.race,
    required this.id,
    this.sameDayManualRaces = const [],
  });

  /// A forrás Excel-sor.
  final LegacyRace race;

  /// A kézi verseny determinisztikus azonosítója (UUID v5, M4).
  final String id;

  /// Az ugyanazon a napon már élő, más azonosítójú kézi versenyek:
  /// lehetséges duplikátumok (M4).
  final List<ManualRaceRecord> sameDayManualRaces;

  @override
  int get rowNumber => race.rowNumber;

  @override
  List<Object?> get props => [race, id, sameDayManualRaces];
}

/// Miért nem dönthető el automatikusan egy sor párosítása.
enum AmbiguityReason {
  /// A napon több telemetriás verseny van.
  severalOnDay,

  /// Kétnapos sor, de a két napon nem pontosan egy-egy verseny van.
  twoDayMismatch,

  /// Egy telemetriás verseny több sorhoz is párosulna.
  sharedCandidate,
}

/// Egy sor, amelyről a `--match` dönt; addig semmilyen formában nem
/// íródik.
final class AmbiguousRow extends LegacyPlanItem {
  /// A [race] sor a [candidates] jelöltekkel, a [reason] okból.
  const AmbiguousRow({
    required this.race,
    required this.candidates,
    required this.reason,
  });

  /// A forrás Excel-sor.
  final LegacyRace race;

  /// A szóba jöhető telemetriás versenyek.
  final List<TelemetryCandidate> candidates;

  /// A kétértelműség oka.
  final AmbiguityReason reason;

  @override
  int get rowNumber => race.rowNumber;

  @override
  List<Object?> get props => [race, candidates, reason];
}

/// Egy hibás Excel-sor; nem íródik (M2).
final class RejectedRow extends LegacyPlanItem {
  /// A [rejection] elutasítás.
  const RejectedRow(this.rejection);

  /// A sor hibái.
  final LegacyRowRejection rejection;

  @override
  int get rowNumber => rejection.rowNumber;

  @override
  List<Object?> get props => [rejection];
}
