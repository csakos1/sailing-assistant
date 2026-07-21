import 'package:domain/src/entities/boat_state.dart';
import 'package:domain/src/repositories/domain_event.dart';
import 'package:domain/src/value_objects/bearing.dart';

/// A hajó esemény-folyamát [BoatState]-té foldoló pure reducer
/// (ADR 0017 D2, ARCHITECTURE.md 8.6).
///
/// Korábban az `apps/phone` `boatStateProvider`-ében élt szabad
/// függvényként; a háttér-`RaceEngine` (ADR 0017) Riverpod nélkül is
/// használja, ezért a domainbe került. A [call] tiszta: nincs
/// mellékhatás, adott bemenetre adott kimenet.
///
/// A `lastUpdate` mindig a receipt-idő; az [InstrumentTimeEvent]
/// GPS-instantja **csak** az `instrumentTimeUtc`-be megy. A [WindEvent]
/// no-op (a szelet a wind-állapot tartja, nem a [BoatState]).
class BoatStateReducer {
  /// Konstans reducer — nincs állapota.
  const BoatStateReducer();

  /// Foldol: `current` állapot + `event` esemény + `now` receipt-idő → új
  /// [BoatState]. Az exhaustive switch a sealed [DomainEvent] minden
  /// leafjét kezeli; a [HeadingEvent] a `Bearing` reference-e szerint a
  /// magneticNorth/trueNorth mezőbe kerül.
  BoatState call(BoatState current, DomainEvent event, DateTime now) {
    return switch (event) {
      PositionEvent(:final position) => current.copyWith(
        position: position,
        lastUpdate: now,
      ),
      HeadingEvent(:final heading) =>
        heading.reference == BearingReference.magneticNorth
            ? current.copyWith(headingMagnetic: heading, lastUpdate: now)
            : current.copyWith(headingTrue: heading, lastUpdate: now),
      CogSogEvent(:final courseOverGround, :final speedOverGround) =>
        current.copyWith(
          courseOverGround: courseOverGround,
          speedOverGround: speedOverGround,
          lastUpdate: now,
        ),
      SpeedEvent(:final speedThroughWater) => current.copyWith(
        speedThroughWater: speedThroughWater,
        lastUpdate: now,
      ),
      DepthEvent(:final depth) => current.copyWith(
        depth: depth,
        lastUpdate: now,
      ),
      InstrumentTimeEvent() => current.copyWith(
        instrumentTimeUtc: event.timestamp,
        lastUpdate: now,
      ),
      WindEvent() => current,
    };
  }
}
