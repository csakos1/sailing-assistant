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
  /// Az építés a minták két változatából.
  ///
  /// Az [allSamples] a webes szűrők utáni minták (az elszámoláshoz), a
  /// [steadySamples] ugyanez az állandósult szél szűrőjével
  /// (`steadyWindMask`); a polár az utóbbiak közül a
  /// [PolarBuildRejection] szűrőin átjutókból épül.
  factory PolarBuild.of({
    required List<LabSample> allSamples,
    required List<LabSample> steadySamples,
    PolarSmoothingParameters parameters = const PolarSmoothingParameters(),
  }) {
    final accepted = [
      for (final sample in steadySamples)
        if (PolarBuildRejection.of(sample) == null) sample,
    ];
    final axes = PolarBuildAxes.forSamples(accepted);
    final raw = RawPolarGrid.of(accepted, axes: axes);
    final smoothed = SmoothedPolarGrid.of(raw, parameters: parameters);
    return PolarBuild._(
      accounting: PolarBuildSeasonAccounting.of(
        allSamples: allSamples,
        steadySamples: steadySamples,
      ),
      acceptedSamples: List.unmodifiable(accepted),
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
