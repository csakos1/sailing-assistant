import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/features/shell/day_race_provider.dart';
import 'package:phone/features/shell/instruments_tab_status.dart';
import 'package:phone/providers/active_race_provider.dart';
import 'package:phone/providers/connection_status_provider.dart';
import 'package:phone/providers/engine_session_provider.dart';
import 'package:phone/providers/local_wall_clock_provider.dart';
import 'package:phone/providers/race_snapshot_provider.dart';

/// A sáv Műszerek-cellájának élő állapota (ADR 0056 D2).
final AutoDisposeProvider<InstrumentsTabStatus> instrumentsTabStatusProvider =
    Provider.autoDispose<InstrumentsTabStatus>(
      (ref) => instrumentsTabStatusOf(
        session: ref.watch(engineSessionProvider),
        connection: ref.watch(connectionStatusProvider),
        selectedRace: ref.watch(activeRaceProvider),
        dayRace: ref.watch(dayRaceProvider),
        toLocal: ref.watch(localWallClockProvider),
        hasSessionData: ref.watch(
          raceSnapshotProvider.select(
            (snapshot) => (snapshot?.eventCount ?? 0) > 0,
          ),
        ),
      ),
    );
