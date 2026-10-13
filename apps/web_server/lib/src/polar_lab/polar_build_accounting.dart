import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:web_server/src/polar_lab/lab_sample.dart';
import 'package:web_server/src/polar_lab/polar_build_rejection.dart';

/// Egy szezon mintáinak elszámolása a polár építésekor (ADR 0058 D6): mennyi
/// idő volt érvényes, mennyi esett ki és miért, mennyi került a polárba.
@immutable
final class PolarBuildSeasonAccounting extends Equatable {
  /// Elszámolás a megadott időkkel (másodperc).
  const PolarBuildSeasonAccounting({
    required this.season,
    required this.raceCount,
    required this.validSeconds,
    required this.frozenSeconds,
    required this.unsteadySeconds,
    required this.rejectedSeconds,
    required this.usedSeconds,
  });

  /// A szezon éve.
  final int season;

  /// A szezon versenyeinek száma, amelyekből érvényes minta jött.
  final int raceCount;

  /// Az érvényes minták ideje (a webes szűrők után).
  final int validSeconds;

  /// A beragadt szélirány-mérő miatt kiesett idő.
  final int frozenSeconds;

  /// A nem állandósult szél miatt kiesett idő.
  final int unsteadySeconds;

  /// A többi szűrő miatt kiesett idő okonként.
  final Map<PolarBuildRejection, int> rejectedSeconds;

  /// A polárba került idő.
  final int usedSeconds;

  @override
  List<Object?> get props => [
    season,
    raceCount,
    validSeconds,
    frozenSeconds,
    unsteadySeconds,
    rejectedSeconds,
    usedSeconds,
  ];

  /// Szezononkénti elszámolás növekvő évsorrendben.
  ///
  /// Az [allSamples] a webes szűrők utáni minták, az [unfrozenSamples]
  /// ugyanez a beragadt szélirány maszkjával, a [steadySamples] mindkét
  /// maszkkal (egymás részhalmazai, mert a maszk a tüske-döntést nem
  /// változtatja). A beragadt és a nem állandósult idő a szomszédos
  /// halmazok különbsége; a többi ok a [steadySamples]-ből számol
  /// ([PolarBuildRejection.of], a [maximumDownwindVmgRatio] küszöbbel).
  static List<PolarBuildSeasonAccounting> of({
    required Iterable<LabSample> allSamples,
    required Iterable<LabSample> unfrozenSamples,
    required Iterable<LabSample> steadySamples,
    double maximumDownwindVmgRatio =
        PolarBuildRejection.defaultMaximumDownwindVmgRatio,
  }) {
    final valid = _secondsBySeason(allSamples);
    final unfrozen = _secondsBySeason(unfrozenSamples);
    final steady = _secondsBySeason(steadySamples);
    final races = <int, Set<String>>{};
    for (final sample in allSamples) {
      races.putIfAbsent(sample.season, () => <String>{}).add(sample.raceId);
    }
    final rejected = <int, Map<PolarBuildRejection, int>>{};
    for (final sample in steadySamples) {
      final reason = PolarBuildRejection.of(
        sample,
        maximumDownwindVmgRatio: maximumDownwindVmgRatio,
      );
      if (reason == null) continue;
      rejected
          .putIfAbsent(sample.season, () => <PolarBuildRejection, int>{})
          .update(
            reason,
            (seconds) => seconds + sample.seconds,
            ifAbsent: () => sample.seconds,
          );
    }
    final seasons = {...valid.keys, ...steady.keys}.toList()..sort();
    return [
      for (final season in seasons)
        _seasonOf(
          season: season,
          raceCount: races[season]?.length ?? 0,
          validSeconds: valid[season] ?? 0,
          unfrozenSeconds: unfrozen[season] ?? 0,
          steadySeconds: steady[season] ?? 0,
          rejectedSeconds: rejected[season] ?? const {},
        ),
    ];
  }
}

Map<int, int> _secondsBySeason(Iterable<LabSample> samples) {
  final seconds = <int, int>{};
  for (final sample in samples) {
    seconds.update(
      sample.season,
      (sum) => sum + sample.seconds,
      ifAbsent: () => sample.seconds,
    );
  }
  return seconds;
}

PolarBuildSeasonAccounting _seasonOf({
  required int season,
  required int raceCount,
  required int validSeconds,
  required int unfrozenSeconds,
  required int steadySeconds,
  required Map<PolarBuildRejection, int> rejectedSeconds,
}) {
  final rejectedTotal = rejectedSeconds.values.fold(
    0,
    (sum, seconds) => sum + seconds,
  );
  return PolarBuildSeasonAccounting(
    season: season,
    raceCount: raceCount,
    validSeconds: validSeconds,
    frozenSeconds: validSeconds - unfrozenSeconds,
    unsteadySeconds: unfrozenSeconds - steadySeconds,
    rejectedSeconds: Map.unmodifiable(rejectedSeconds),
    usedSeconds: steadySeconds - rejectedTotal,
  );
}
