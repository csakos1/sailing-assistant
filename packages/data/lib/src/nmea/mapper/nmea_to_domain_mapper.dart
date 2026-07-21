import 'package:data/src/nmea/mapper/depth_source_selector.dart';
import 'package:data/src/nmea/mapper/wind_aggregator.dart';
import 'package:data/src/nmea/parser/decoded_sentence.dart';
import 'package:domain/domain.dart';

/// A dekódolt NMEA mondatokat ([DecodedSentence]) domain-eseményekké
/// ([DomainEvent]) fordítja — a Phase 2 parse-pipeline utolsó lépése
/// (ARCHITECTURE.md 6.4).
///
/// **Stateful**, két okból. Egyrészt a szél-mondatok aggregálását egy
/// élettartamra szóló [WindAggregator]-ra delegálja (a látszó + valódi szél
/// mezők több mondatból állnak össze). Másrészt a mélység forrás-választását
/// egy [DepthSourceSelector]-ra: a `DBT` és a `DPT` ugyanazt az adatot szórja
/// párhuzamosan, és a `DBT`-elsőbbség csak a stream szintjén érvényesíthető
/// (ADR 0031 Addendum 2). A többi mondat állapotmentesen, közvetlenül
/// képződik le.
///
/// Időbélyeg-politika: minden esemény az injektált `now` app-órát kapja —
/// **kivéve az [InstrumentTimeEvent]-et**, ami az `RMC` GPS-instantját
/// (`DecodedRmc.timestampUtc`) hordozza. Az `RMC`-ből bontott
/// [PositionEvent] / [CogSogEvent] is `now`-t kap, nem a GPS-időt.
class NmeaToDomainMapper {
  // A szél-állapot akkumulátora a stream teljes élettartamára (a látszó +
  // valódi szél mezők több mondatból állnak össze).
  final WindAggregator _windAggregator = WindAggregator();

  // A mélység forrás-választója a stream teljes élettartamára (a DBT-t és a
  // DPT-t a Vulcan egyszerre szórja).
  final DepthSourceSelector _depthSourceSelector = DepthSourceSelector();

  /// A [sentence]-t domain-esemény(ek)re fordítja az injektált [now]
  /// időbélyeggel.
  ///
  /// Lista a visszatérés, mert egy `RMC` három eseményre bomlik, egy
  /// variációs `HDG` kettőre (magnetic + true), egy apparent nélküli
  /// szél-mondat pedig nullára (üres lista, apparent-gate) — ahogy az
  /// elnyomott `DPT` mélység is (forrás-gate).
  List<DomainEvent> map(DecodedSentence sentence, DateTime now) {
    return switch (sentence) {
      DecodedWind(:final reference, :final angle, :final speed) =>
        switch (reference) {
          WindReference.apparent => [
            WindEvent(_windAggregator.applyApparent(angle, speed, now)),
          ],
          WindReference.true_ => _windEventsFor(
            _windAggregator.applyTrueWater(angle, speed, now),
          ),
        },
      DecodedWindDirection(:final direction) => _windEventsFor(
        _windAggregator.applyTrueDirection(direction, now),
      ),
      DecodedRmc(
        :final position,
        :final courseOverGround,
        :final speedOverGround,
        :final timestampUtc,
      ) =>
        [
          PositionEvent(position, now),
          CogSogEvent(courseOverGround, speedOverGround, now),
          InstrumentTimeEvent(timestampUtc),
        ],
      DecodedPosition(:final position) => [PositionEvent(position, now)],
      DecodedCogSog(:final courseOverGround, :final speedOverGround) => [
        CogSogEvent(courseOverGround, speedOverGround, now),
      ],
      DecodedHeading(:final heading, :final headingTrue) => [
        HeadingEvent(heading, now),
        if (headingTrue != null) HeadingEvent(headingTrue, now),
      ],
      DecodedSpeed(:final speedThroughWater) => [
        SpeedEvent(speedThroughWater, now),
      ],
      DecodedDepth(:final depth, :final source) => _depthEventsFor(
        depth,
        source,
        now,
      ),
    };
  }

  // A szél-aggregátor null snapshotja (apparent-gate) üres listát ad;
  // különben egyetlen WindEvent.
  List<DomainEvent> _windEventsFor(WindData? snapshot) =>
      snapshot == null ? const [] : [WindEvent(snapshot)];

  // Az elsődleges (DBT) forrás mindig emittál és megnyitja az elnyomási
  // ablakot; a fallback (DPT) csak akkor, ha az ablak már lejárt.
  List<DomainEvent> _depthEventsFor(
    Depth depth,
    DepthSource source,
    DateTime now,
  ) {
    final shouldEmit = _depthSourceSelector.shouldEmit(
      isPrimary: source == DepthSource.dbt,
      now: now,
    );
    return shouldEmit ? [DepthEvent(depth, now)] : const [];
  }
}
