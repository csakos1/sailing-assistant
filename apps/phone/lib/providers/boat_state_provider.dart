import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/providers/clock_provider.dart';
import 'package:phone/providers/nmea_stream_provider.dart';

/// A hajó pillanatnyi állapota az NMEA esemény-folyamból foldolva
/// (ADR 0010 D1, ARCHITECTURE.md 8.6).
///
/// Seedelt `AutoDisposeNotifier` a `connectionStatusProvider` (8.3)
/// mintájára: a `build()` üres [BoatState]-tel seedel az app-órából, a
/// [NmeaStream.events]-re iratkozik, és minden eseményt a [_reduce] foldol be.
/// A `lastUpdate` mindig a `clockProvider`-óra (receipt-idő); az
/// [InstrumentTimeEvent] GPS-instantja **csak** az `instrumentTimeUtc`-be megy.
final boatStateProvider =
    AutoDisposeNotifierProvider<BoatStateNotifier, BoatState>(
      BoatStateNotifier.new,
    );

/// A [boatStateProvider] notifier-implementációja.
class BoatStateNotifier extends AutoDisposeNotifier<BoatState> {
  @override
  BoatState build() {
    final clock = ref.watch(clockProvider);
    final stream = ref.watch(nmeaStreamProvider);
    final sub = stream.events.listen((event) {
      state = _reduce(state, event, clock());
    });
    ref.onDispose(sub.cancel);
    return BoatState(lastUpdate: clock());
  }
}

// Pure reducer: esemény + receipt-idő → új BoatState. Az exhaustive switch a
// sealed DomainEvent minden leafjét kezeli; a HeadingEvent a Bearing
// reference-e szerint a magneticNorth/trueNorth mezőbe kerül; a WindEvent
// változatlanul adja vissza az állapotot (a szél a windDataProvider-é).
BoatState _reduce(BoatState current, DomainEvent event, DateTime now) {
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
    InstrumentTimeEvent() => current.copyWith(
      instrumentTimeUtc: event.timestamp,
      lastUpdate: now,
    ),
    WindEvent() => current,
  };
}
