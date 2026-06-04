import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Az élő verseny-session explicit be/ki kapcsolója (ADR 0017 A12/A13).
///
/// A háttér-engine lifecycle-ját EZ vezérli, NEM az `activeRaceProvider`
/// nem-null-sága — különben az `activeRacePersistenceProvider` boot-restore-ja
/// akaratlanul indítaná az engine-t. Csak user-akció billenti: az „Élő nézet"
/// megnyitása `true`-ra, a „Leállítás" akció `false`-ra. A restore az
/// activeRace-t visszatölti, de ez a flag `false` marad → boot-kor nincs
/// auto-indítás.
final raceEngineSessionProvider =
    NotifierProvider<RaceEngineSessionNotifier, bool>(
      RaceEngineSessionNotifier.new,
    );

/// A [raceEngineSessionProvider] notifierje: explicit start/stop.
class RaceEngineSessionNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  /// Élő session indítása (az „Élő nézet" megnyitásakor).
  void start() => state = true;

  /// Élő session leállítása (a „Leállítás" akció).
  void stop() => state = false;
}
