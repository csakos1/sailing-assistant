import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';
import 'package:uuid/uuid.dart';
import 'package:web_server/src/legacy/budapest_time.dart';
import 'package:web_server/src/legacy/legacy_import_plan.dart';
import 'package:web_server/src/legacy/legacy_plan_item.dart';
import 'package:web_server/src/legacy/legacy_race.dart';
import 'package:web_server/src/legacy/legacy_row_rejection.dart';
import 'package:web_server/src/legacy/telemetry_candidate.dart';
import 'package:web_server/src/web_db/manual_race_record.dart';

/// Az Excel-import terve (ADR 0048 D7, Addendum 6 M1, M4, M5).
///
/// Pure: a sorokból, az archívum befejezett versenyeiből, a meglévő kézi
/// versenyekből és a `--match` döntésekből (versenyazonosító → sor) áll
/// össze. Nem ír semmit. A tételek a sorok sorrendjében jönnek, a
/// kétnapos sor két tétele napsorrendben.
LegacyImportPlan planLegacyImport({
  required List<Result<LegacyRace, LegacyRowRejection>> rows,
  required List<TelemetryCandidate> telemetryRaces,
  required List<ManualRaceRecord> manualRaces,
  Map<String, int> explicitMatches = const {},
  String Function(LegacyRace race) manualIdOf = legacyManualRaceId,
}) {
  final races = [
    for (final row in rows)
      if (row case Ok(:final value)) value,
  ];
  final explicit = _ExplicitMatches.resolve(
    explicitMatches,
    races: races,
    rejectedRows: {
      for (final row in rows)
        if (row case Err(:final error)) error.rowNumber,
    },
    telemetryRaces: telemetryRaces,
  );
  final proposals = _withSharedCandidatesMarked({
    for (final race in races)
      race.rowNumber: _proposalFor(race, explicit, telemetryRaces),
  });
  final items = <LegacyPlanItem>[
    for (final row in rows)
      ...switch (row) {
        Err(:final error) => [RejectedRow(error)],
        // Minden érvényes sornak van javaslata: ugyanebből a listából
        // épült, ezért a `!` biztonságos.
        Ok(:final value) => _itemsOf(
          value,
          proposals[value.rowNumber]!,
          manualRaces,
          manualIdOf,
        ),
      },
  ];
  return LegacyImportPlan(
    items: items,
    telemetryOnly: _unclaimed(telemetryRaces, proposals.values),
    matchProblems: explicit.problems,
  );
}

/// A kézi verseny determinisztikus azonosítója (M4): UUID v5 a
/// `Namespace.url` névtérben a `legacy:<nap>:<név>` kulcsból.
String legacyManualRaceId(LegacyRace race) => const Uuid().v5(
  Namespace.url.value,
  'legacy:${race.date.toIso()}:${race.name}',
);

/// Egy sor párosítási javaslata, mielőtt az ütközések kiderülnek.
sealed class _Proposal {
  const _Proposal();
}

final class _Single extends _Proposal {
  const _Single(this.target, {required this.isExplicit});
  final TelemetryCandidate target;
  final bool isExplicit;
}

final class _Split extends _Proposal {
  const _Split(this.first, this.second, {required this.isExplicit});
  final TelemetryCandidate first;
  final TelemetryCandidate second;
  final bool isExplicit;
}

final class _Manual extends _Proposal {
  const _Manual();
}

final class _Ambiguous extends _Proposal {
  const _Ambiguous(this.candidates, this.reason);
  final List<TelemetryCandidate> candidates;
  final AmbiguityReason reason;
}

/// A `--match` döntések soronként, a hibáikkal.
final class _ExplicitMatches {
  _ExplicitMatches(this.byRow, this.problems);

  factory _ExplicitMatches.resolve(
    Map<String, int> matches, {
    required List<LegacyRace> races,
    required Set<int> rejectedRows,
    required List<TelemetryCandidate> telemetryRaces,
  }) {
    final rowsByNumber = {for (final race in races) race.rowNumber: race};
    final byId = {for (final race in telemetryRaces) race.id: race};
    final byRow = <int, List<TelemetryCandidate>>{};
    final problems = <String>[];
    for (final MapEntry(key: raceId, value: rowNumber) in matches.entries) {
      final target = byId[raceId];
      if (target == null) {
        problems.add('--match $raceId: nincs ilyen befejezett verseny');
      } else if (rejectedRows.contains(rowNumber)) {
        problems.add('--match $raceId=$rowNumber: a sor hibás');
      } else if (!rowsByNumber.containsKey(rowNumber)) {
        problems.add('--match $raceId=$rowNumber: nincs ilyen sor');
      } else {
        byRow.putIfAbsent(rowNumber, () => []).add(target);
      }
    }
    for (final MapEntry(key: rowNumber, value: targets) in byRow.entries) {
      targets.sort((a, b) => a.startedAt.compareTo(b.startedAt));
      final isTwoDay = rowsByNumber[rowNumber]?.twoDayResults != null;
      if (targets.length > 2 || (targets.length == 2 && !isTwoDay)) {
        problems.add(
          '$rowNumber. sor: ${targets.length} --match, '
          'de a sor ${isTwoDay ? 'legfeljebb kétnapos' : 'egynapos'}',
        );
      }
    }
    return _ExplicitMatches(byRow, problems);
  }

  final Map<int, List<TelemetryCandidate>> byRow;
  final List<String> problems;

  Set<String> get claimedIds => {
    for (final targets in byRow.values)
      for (final target in targets) target.id,
  };
}

_Proposal _proposalFor(
  LegacyRace race,
  _ExplicitMatches explicit,
  List<TelemetryCandidate> telemetryRaces,
) {
  final targets = explicit.byRow[race.rowNumber];
  if (targets != null) {
    return switch (targets) {
      [final target] => _Single(target, isExplicit: true),
      [final first, final second] when race.twoDayResults != null => _Split(
        first,
        second,
        isExplicit: true,
      ),
      // A hibás számú --match a problémák közé került; a sor addig vár.
      _ => _Ambiguous(targets, AmbiguityReason.severalOnDay),
    };
  }
  // Egy másik sornak --match-csel odaadott verseny nem jelölt.
  final claimed = explicit.claimedIds;
  List<TelemetryCandidate> candidatesOn(CalendarDate day) => [
    for (final candidate in telemetryRaces)
      if (candidate.day == day && !claimed.contains(candidate.id)) candidate,
  ];
  final sameDay = candidatesOn(race.date);
  if (race.twoDayResults == null) {
    return switch (sameDay) {
      [] => const _Manual(),
      [final target] => _Single(target, isExplicit: false),
      _ => _Ambiguous(sameDay, AmbiguityReason.severalOnDay),
    };
  }
  final nextDay = candidatesOn(nextCalendarDay(race.date));
  return switch ((sameDay, nextDay)) {
    ([], []) => const _Manual(),
    ([final first], [final second]) => _Split(
      first,
      second,
      isExplicit: false,
    ),
    _ => _Ambiguous([...sameDay, ...nextDay], AmbiguityReason.twoDayMismatch),
  };
}

// Ha egy telemetriás versenyre több sor is igényt tart (pl. egy kétnapos
// sor második napja egy másik sor napjára esik), egyik sem dönthető el.
Map<int, _Proposal> _withSharedCandidatesMarked(
  Map<int, _Proposal> proposals,
) {
  final claims = <String, int>{};
  for (final proposal in proposals.values) {
    for (final target in _targetsOf(proposal)) {
      claims.update(target.id, (count) => count + 1, ifAbsent: () => 1);
    }
  }
  // A claims minden javasolt versenyt tartalmaz, ezért a `!` biztonságos.
  return {
    for (final MapEntry(key: rowNumber, value: proposal) in proposals.entries)
      rowNumber: _targetsOf(proposal).any((target) => claims[target.id]! > 1)
          ? _Ambiguous(_targetsOf(proposal), AmbiguityReason.sharedCandidate)
          : proposal,
  };
}

List<TelemetryCandidate> _targetsOf(_Proposal proposal) => switch (proposal) {
  _Single(:final target) => [target],
  _Split(:final first, :final second) => [first, second],
  _Manual() || _Ambiguous() => const [],
};

List<LegacyPlanItem> _itemsOf(
  LegacyRace race,
  _Proposal proposal,
  List<ManualRaceRecord> manualRaces,
  String Function(LegacyRace race) manualIdOf,
) => switch (proposal) {
  _Single(:final target, :final isExplicit) => [
    PlannedResult(
      race: race,
      target: target,
      result: race.result,
      isExplicit: isExplicit,
    ),
  ],
  _Split(:final first, :final second, :final isExplicit) => [
    for (final (day, target) in [(1, first), (2, second)])
      PlannedResult(
        race: race,
        target: target,
        // A _Split csak kétnapos sorból jön, ezért a felbontás megvan.
        result: day == 1
            ? race.twoDayResults!.first
            : race.twoDayResults!.second,
        isExplicit: isExplicit,
        splitDay: day,
      ),
  ],
  _Manual() => [_manualItemOf(race, manualRaces, manualIdOf)],
  _Ambiguous(:final candidates, :final reason) => [
    AmbiguousRow(race: race, candidates: candidates, reason: reason),
  ],
};

PlannedManualRace _manualItemOf(
  LegacyRace race,
  List<ManualRaceRecord> manualRaces,
  String Function(LegacyRace race) manualIdOf,
) {
  final id = manualIdOf(race);
  return PlannedManualRace(
    race: race,
    id: id,
    sameDayManualRaces: [
      for (final record in manualRaces)
        if (record.input.date == race.date && record.id != id) record,
    ],
  );
}

// Ami se javaslatban, se kétértelmű jelöltként nem szerepel.
List<TelemetryCandidate> _unclaimed(
  List<TelemetryCandidate> telemetryRaces,
  Iterable<_Proposal> proposals,
) {
  final mentioned = {
    for (final proposal in proposals)
      ...switch (proposal) {
        _Ambiguous(:final candidates) => [
          for (final candidate in candidates) candidate.id,
        ],
        _ => [for (final target in _targetsOf(proposal)) target.id],
      },
  };
  return [
    for (final race in telemetryRaces)
      if (!mentioned.contains(race.id)) race,
  ]..sort((a, b) => a.startedAt.compareTo(b.startedAt));
}
