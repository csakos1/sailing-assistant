import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/providers/race_snapshot_provider.dart';

/// A következő bója predikciója az engine-snapshotból tükrözve — a v1 szíve
/// (ADR 0017 addendum A4, ARCHITECTURE.md 8.8).
///
/// A 7-bg-d előtt a `ComputeMarkPrediction`-t futtatta 1 Hz-en a UI-oldali
/// `boatState` + `windShiftTrend` + aktív bója alapján; azóta a számítás az
/// engine-ben fut, és ez a `raceSnapshotProvider` `prediction` mezőjét tükrözi
/// (`null` ha nincs aktív bója / pozíció). Az élő aktív bója a
/// `prediction.mark` (A3).
final markPredictionProvider = AutoDisposeProvider<MarkPrediction?>(
  (ref) => ref.watch(raceSnapshotProvider)?.prediction,
);
