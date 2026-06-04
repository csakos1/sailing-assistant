import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A háttér-engine foreground-service indításának utolsó hibája, vagy `null`,
/// ha nincs (ADR 0017 A13). A `raceEngineLifecycleProvider` állítja a
/// `ServiceRequestFailure`-ből; a `LiveRaceScreen` státuszsora jeleníti meg.
final engineServiceErrorProvider = StateProvider<String?>((ref) => null);
