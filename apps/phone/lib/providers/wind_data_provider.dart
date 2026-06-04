import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/providers/race_snapshot_provider.dart';

/// A legfrissebb szél-snapshot az engine-snapshotból tükrözve
/// (ADR 0017 addendum A4, ARCHITECTURE.md 8.8).
///
/// A 7-bg-d előtt a `nmeaStreamProvider.events` `WindEvent`-jeit követte;
/// azóta a `raceSnapshotProvider` `wind` mezőjét tükrözi (read-only), `null`
/// ha még nincs adat.
final windDataProvider =
    AutoDisposeNotifierProvider<WindDataNotifier, WindData?>(
      WindDataNotifier.new,
    );

/// A [windDataProvider] notifier-implementációja.
class WindDataNotifier extends AutoDisposeNotifier<WindData?> {
  @override
  WindData? build() => ref.watch(raceSnapshotProvider)?.wind;
}
