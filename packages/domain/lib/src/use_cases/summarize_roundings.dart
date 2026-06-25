import 'package:domain/src/value_objects/rounding_result.dart';
import 'package:domain/src/value_objects/rounding_summary.dart';

/// A megkerülés-eredményekből összegző mutatókat számol (ADR 0034 D6 fej):
/// átlagos |delta|, hibasáv-találati arány, átlagos lead-time. Tiszta use
/// case; a CLI `_summary`-jával azonos aritmetika, strukturált alakban.
class SummarizeRoundings {
  /// Paraméter nélküli, const use case.
  const SummarizeRoundings();

  /// A [results] aggregátumai egy [RoundingSummary]-ben.
  RoundingSummary call(List<RoundingResult> results) {
    final absDeltas = <double>[
      for (final result in results)
        if (result.deltaDeg != null) result.deltaDeg!.abs(),
    ];
    final withBand = <RoundingResult>[
      for (final result in results)
        if (result.isWithinBand != null) result,
    ];
    final leadSeconds = <int>[
      for (final result in results)
        if (result.leadTime != null) result.leadTime!.inSeconds,
    ];
    return RoundingSummary(
      avgAbsDeltaDeg: absDeltas.isEmpty ? null : _mean(absDeltas),
      bandHits: withBand.where((result) => result.isWithinBand!).length,
      bandTotal: withBand.length,
      avgLeadTime: leadSeconds.isEmpty
          ? null
          : Duration(seconds: _meanInt(leadSeconds)),
    );
  }
}

double _mean(List<double> values) =>
    values.reduce((a, b) => a + b) / values.length;

int _meanInt(List<int> values) =>
    (values.reduce((a, b) => a + b) / values.length).round();
