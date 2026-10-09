import 'package:domain/domain.dart';
import 'package:web_server/src/web_db/legacy_track_repository.dart';

/// A [PolarSampleReader] a régi trackekre: a `legacy_track_samples`
/// polár-oszlopaiból (ADR 0049 D13, ADR 0050 D6, Addendum 4 U3).
///
/// A szélszög és a szélsebesség a mediánok, mert a `foretack.pol` is
/// azokból épült; a vízsebesség a pillanatérték. Egy minta 10 másodpercet
/// ér.
class LegacyPolarSampleReader {
  /// Olvasó a [_tracks] fölött.
  const LegacyPolarSampleReader(this._tracks);

  final LegacyTrackRepository _tracks;

  /// A régi YDVR-napló mintáinak súlya másodpercben (ADR 0050 D6).
  static const int sampleSeconds = 10;

  /// A `raceId` verseny polár-mintái a [window]-ból, időrendben.
  Future<List<PolarSample>> call(String raceId, TimeWindow? window) async => [
    for (final sample in await _tracks.readWindow(raceId, window))
      PolarSample(
        timestamp: sample.timestamp,
        twaDeg: sample.polarTwaDeg,
        twsMps: sample.polarTwsMps,
        stwMps: sample.stwMps,
        durationSeconds: sampleSeconds,
      ),
  ];
}
