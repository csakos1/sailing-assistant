import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/features/race_detail/post_race_analysis.dart';
import 'package:phone/features/race_detail/track_point.dart';
import 'package:phone/providers/rounding_sample_reader_provider.dart';

/// A befejezett verseny on-device post-race elemzése (ADR 0034 D4).
///
/// Race-enként (family a `raceId`-re) beolvassa a rögzített pillanatképeket,
/// lefuttatja az `AnalyzeRoundings` + `SummarizeRoundings` use case-eket, és a
/// `RaceDetailScreen` debug-szekciójának ([PostRaceAnalysis]) adja vissza.
/// autoDispose: a detail-képernyő elhagyásakor felszabadul.
final postRaceAnalysisProvider =
    AutoDisposeFutureProviderFamily<PostRaceAnalysis, String>(
      (ref, raceId) async {
        final reader = ref.watch(roundingSampleReaderProvider);
        final samples = await reader(raceId);
        final roundings = const AnalyzeRoundings()(samples);
        // A track-pontok a pozíciós mintákból, a sebességgel együtt — a
        // szakaszonkénti gradient-színezéshez (ADR 0034 Addendum 4).
        final trackPoints = <TrackPoint>[
          for (final s in samples)
            if (s.latDeg case final lat?)
              if (s.lonDeg case final lon?)
                TrackPoint(
                  position: Coordinate(latitude: lat, longitude: lon),
                  sogMps: s.sogMps,
                ),
        ];
        return PostRaceAnalysis(
          roundings: roundings,
          summary: const SummarizeRoundings()(roundings),
          trackPoints: trackPoints,
          trackStats: const SummarizeTrack()(samples),
        );
      },
    );
