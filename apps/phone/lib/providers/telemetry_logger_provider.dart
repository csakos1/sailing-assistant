import 'dart:async';

import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/providers/active_race_provider.dart';
import 'package:phone/providers/app_database_provider.dart';
import 'package:phone/providers/clock_provider.dart';
import 'package:phone/providers/nmea_stream_provider.dart';

/// A nyers NMEA 0183 sorok telemetria-logolása, aktív race-hez kötött
/// életciklussal (ADR 0009 D6, ARCHITECTURE.md 9.4).
///
/// Selectorra iratkozik: csak a (versenyzik?, raceId) pár változására épül
/// újra, NEM minden bója-körözésnél. Kizárólag RaceStatus.active alatt logol;
/// notStarted/finished alatt nincs feliratkozás. Fake/replay forrás (nem
/// RawNmeaLineSource) esetén graceful no-op (ADR 0006 minta). A timestamp az
/// injektált órából, a raceId az aktív race-ből jön.
///
/// Mellékhatás-provider (`Provider<void>`): az app-gyökérben egy
/// `ref.watch(telemetryLoggerProvider)` kelti életre, különben sosem épül fel.
final telemetryLoggerProvider = Provider<void>((ref) {
  final raceId = ref.watch(
    activeRaceProvider.select(
      (race) => switch (race) {
        Race(status: RaceStatus.active, :final id) => id,
        _ => null,
      },
    ),
  );
  if (raceId == null) return;

  final source = ref.watch(nmeaStreamProvider);
  // Dart nem promotál független interfészek közt; pattern-match adja a tiszta
  // szűkítést a nyers-sor felületre (vö. rawNmeaLinesProvider).
  if (source case final RawNmeaLineSource rawSource) {
    final logger = TelemetryLoggerImpl(ref.watch(appDatabaseProvider));
    final now = ref.watch(clockProvider);
    final subscription = rawSource.rawLines.listen(
      (line) => unawaited(
        logger.log(
          TelemetryRecord(raceId: raceId, timestamp: now(), rawSentence: line),
        ),
      ),
    );
    ref.onDispose(() {
      // Előbb a sort állítjuk le (a cancel azonnal megszünteti a kézbesítést),
      // majd a logger záró flush-a kiírja a bufferelt sorokat.
      unawaited(subscription.cancel());
      unawaited(logger.dispose());
    });
  }
});
