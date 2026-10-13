import 'package:meta/meta.dart';
import 'package:web_server/src/polar_lab/lab_sample.dart';
import 'package:web_server/src/polar_lab/polar_build_accounting.dart';
import 'package:web_server/src/polar_lab/polar_build_axes.dart';
import 'package:web_server/src/polar_lab/polar_build_rejection.dart';
import 'package:web_server/src/polar_lab/polar_file_text.dart';
import 'package:web_server/src/polar_lab/raw_polar_grid.dart';
import 'package:web_server/src/polar_lab/smoothed_polar_grid.dart';

/// Egy polár-építés teljes eredménye (ADR 0058 D1, D4, D6, D7): az
/// elszámolás, a nyers és a kész rács, és a `.pol` szövege.
///
/// Pure: ugyanarra a bemenetre ugyanazt adja; a `bin/build_polar.dart`
/// csak az IO-t végzi körülötte.
@immutable
final class PolarBuild {
  /// Az építés a minták három változatából.
  ///
  /// Az [allSamples] a webes szűrők utáni minták, az [unfrozenSamples]
  /// ugyanez a beragadt szélirány maszkjával (`frozenVaneMask`), a
  /// [steadySamples] ezen felül az állandósult szél maszkjával
  /// (`steadyWindMask`); az első kettő az elszámoláshoz kell. A polár a
  /// [steadySamples] közül a [PolarBuildRejection] szűrőin átjutókból
  /// épül; a mély hátszeles VMG küszöbe a [maximumDownwindVmgRatio].
  factory PolarBuild.of({
    required List<LabSample> allSamples,
    required List<LabSample> unfrozenSamples,
    required List<LabSample> steadySamples,
    PolarSmoothingParameters parameters = const PolarSmoothingParameters(),
    double maximumDownwindVmgRatio =
        PolarBuildRejection.defaultMaximumDownwindVmgRatio,
  }) {
    final accepted = _passing(steadySamples, maximumDownwindVmgRatio);
    // A VMG-szűrő nélkül átjutó minták: a 8. szakasz ezekből mutatja,
    // hol a küszöb.
    final vmgCandidates = _passing(steadySamples, double.infinity);
    final axes = PolarBuildAxes.forSamples(accepted);
    final raw = RawPolarGrid.of(accepted, axes: axes);
    final smoothed = SmoothedPolarGrid.of(raw, parameters: parameters);
    return PolarBuild._(
      accounting: PolarBuildSeasonAccounting.of(
        allSamples: allSamples,
        unfrozenSamples: unfrozenSamples,
        steadySamples: steadySamples,
        maximumDownwindVmgRatio: maximumDownwindVmgRatio,
      ),
      acceptedSamples: List.unmodifiable(accepted),
      vmgCandidateSamples: List.unmodifiable(vmgCandidates),
      maximumDownwindVmgRatio: maximumDownwindVmgRatio,
      strongWindSeconds: PolarBuildAxes.strongWindSecondsOf(accepted),
      parameters: parameters,
      raw: raw,
      smoothed: smoothed,
      polarText: polarFileText(smoothed),
    );
  }

  const PolarBuild._({
    required this.accounting,
    required this.acceptedSamples,
    required this.vmgCandidateSamples,
    required this.maximumDownwindVmgRatio,
    required this.strongWindSeconds,
    required this.parameters,
    required this.raw,
    required this.smoothed,
    required this.polarText,
  });

  /// Az elszámolás szezononként.
  final List<PolarBuildSeasonAccounting> accounting;

  /// A polárba került minták (a szűrők után); a diagnosztikához.
  final List<LabSample> acceptedSamples;

  /// A minták, amelyek a mély hátszeles VMG-szűrő nélkül a polárba
  /// kerülnének; a diagnosztikához.
  final List<LabSample> vmgCandidateSamples;

  /// A mély hátszeles VMG és a TWS legnagyobb aránya, amellyel épült.
  final double maximumDownwindVmgRatio;

  /// Az erős szeles oszlop tartományának mért ideje (másodperc); ebből dől
  /// el, hogy a 25 csomós oszlop a tengelyre kerül-e.
  final int strongWindSeconds;

  /// A simítás paraméterei.
  final PolarSmoothingParameters parameters;

  /// A nyers rács.
  final RawPolarGrid raw;

  /// A kész, simított rács.
  final SmoothedPolarGrid smoothed;

  /// A kész rács `.pol` szövege.
  final String polarText;
}

// A [PolarBuildRejection] szűrőin átjutó minták a [ratio] VMG-küszöbbel.
List<LabSample> _passing(List<LabSample> samples, double ratio) => [
  for (final sample in samples)
    if (PolarBuildRejection.of(sample, maximumDownwindVmgRatio: ratio) == null)
      sample,
];
