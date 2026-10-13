import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:web_server/src/polar/legacy_polar_sample_reader.dart';
import 'package:web_server/src/polar/polar_race_catalog.dart';
import 'package:web_server/src/polar_lab/archive_copies.dart';
import 'package:web_server/src/polar_lab/lab_sample_collector.dart';
import 'package:web_server/src/server_log.dart';
import 'package:web_server/src/web_db/legacy_track_repository.dart';
import 'package:web_server/src/web_db/manual_race_repository.dart';
import 'package:web_server/src/web_db/race_result_repository.dart';

/// A mentés-másolat ([copies]) mintagyűjtője, ugyanazzal a versenylistával
/// és olvasókkal, mint a webes polár-statisztika (`PolarStatsCalculator`).
///
/// A [log] a versenylista figyelmeztetéseit kapja; a [corrections] és a
/// [windMedianHalfWindowSeconds] a [LabSampleCollector]-é.
LabSampleCollector archiveSampleCollector(
  ArchiveCopies copies, {
  required List<StwCorrection> corrections,
  required ServerLog log,
  int windMedianHalfWindowSeconds = 0,
}) {
  final tracks = LegacyTrackRepository(copies.webDatabase);
  final catalog = PolarRaceCatalog(
    races: RaceRepositoryImpl(copies.archive),
    results: RaceResultRepository(copies.webDatabase),
    manualRaces: ManualRaceRepository(copies.webDatabase),
    tracks: tracks,
    log: log,
  );
  return LabSampleCollector(
    listRaces: catalog.all,
    readTelemetrySamples: PolarSampleReaderImpl(copies.archive).call,
    readLegacySamples: LegacyPolarSampleReader(tracks).call,
    corrections: corrections,
    windMedianHalfWindowSeconds: windMedianHalfWindowSeconds,
  );
}
