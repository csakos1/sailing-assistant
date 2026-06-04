import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/providers/race_snapshot_provider.dart';

/// A pillanatnyi szélfordulás-trend az engine-snapshotból tükrözve
/// (ADR 0017 addendum A4, ARCHITECTURE.md 8.8).
///
/// A 7-bg-d előtt a `CalculateWindShiftTrend`-et futtatta a UI-oldali
/// `windHistoryProvider` + `tickProvider` alapján; azóta a számítás az
/// engine-ben fut, és ez a `raceSnapshotProvider` `windShiftTrend` mezőjét
/// tükrözi (`null` kevés minta esetén). A teljes trendet visszük (nem bool),
/// hogy az `EvaluateWarnings` változatlan maradjon (A5/OCP).
final windShiftTrendProvider = AutoDisposeProvider<WindShiftTrend?>(
  (ref) => ref.watch(raceSnapshotProvider)?.windShiftTrend,
);
