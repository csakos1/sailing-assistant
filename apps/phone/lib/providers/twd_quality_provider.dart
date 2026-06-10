import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/providers/race_snapshot_provider.dart';

/// A TWD-deriváció minősége az engine-snapshotból tükrözve (ADR 0020 D7,
/// ARCHITECTURE.md 8.8).
///
/// A `raceSnapshotProvider` `twdQuality` mezőjét tükrözi; ha még nincs
/// snapshot, `TwdQuality.unavailable` a biztonságos fallback. A „TWA köv."
/// hero ebből rajzol opacitást a §8.7 szerint.
final twdQualityProvider = AutoDisposeProvider<TwdQuality>(
  (ref) =>
      ref.watch(raceSnapshotProvider)?.twdQuality ?? TwdQuality.unavailable,
);
