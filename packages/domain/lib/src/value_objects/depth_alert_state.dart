import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// A sekélyvíz-riasztás epizód-állapota (ADR 0031 D4).
///
/// Immutable; az `EvaluateDepthAlert` pure use case bemenete és kimenete
/// egyben. Magát az állapotot a `RaceEngine` reducer tartja tickről
/// tickre — a use case nem tárol semmit.
///
/// **A [buzzCounter] MONOTON növekvő**: soha nem csökken, még az epizód
/// lezárásakor vagy szétkapcsoláskor sem. A telefon és az óra a számláló
/// **felfutó élén** rezeg (a `RaceShell` `isRisingToHighConfidence`
/// precedense szerint, ADR 0023), így a latched payload újraküldése nem
/// okoz dupla rezgést.
///
/// A [lowestBuzzedBucket] a ratchet horgonya: az epizódban eddig
/// megrezgetett LEGKISEBB 0,1 m-es vödör. Csak ennél kisebb vödör vált ki
/// új rezgést, ezért a küszöb körül ingadozó mélység nem rezeg újra és
/// újra.
@immutable
class DepthAlertState extends Equatable {
  /// Epizód-állapot; a default értékek a nyugalmi, riasztás nélküli
  /// kiindulást adják.
  const DepthAlertState({
    this.isActive = false,
    this.lowestBuzzedBucket,
    this.buzzCounter = 0,
  });

  /// Fut-e éppen sekélyvíz-epizód. A telefon-banner és az óra-overlay
  /// ettől látszik.
  final bool isActive;

  /// Az epizódban eddig megrezgetett legkisebb 0,1 m-es vödör, vagy
  /// `null`, ha ebben az epizódban még nem volt rezgés.
  final double? lowestBuzzedBucket;

  /// Monoton növekvő rezgés-számláló; a felfutó éle a rezgés-trigger.
  final int buzzCounter;

  @override
  List<Object?> get props => [isActive, lowestBuzzedBucket, buzzCounter];

  @override
  bool? get stringify => true;
}
