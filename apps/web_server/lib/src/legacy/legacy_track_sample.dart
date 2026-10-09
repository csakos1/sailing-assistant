import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';

/// Egy régi track-minta a YDVR-napló `polar.csv`-jéből (ADR 0050 D3).
///
/// SI-egységben áll, a CSV csomóiból átváltva; minden mennyiség `null`
/// lehet, ha a cellája üres volt. A track- és a szél-statisztika ugyanazt a
/// mintát olvassa, ezért mindkét keskeny domain-szerződést megvalósítja:
/// a `SummarizeTrack` és a `SummarizeWind` projekció nélkül kapja meg.
///
/// A polár-mezők (`polar*`) a mediánok, mert a `foretack.pol` is azokból
/// épült (D3); a stat a pillanatértékekből számol, mint a telefonon.
final class LegacyTrackSample extends Equatable
    implements TrackSample, WindSample {
  /// Minta a [timestamp] pillanatban.
  LegacyTrackSample({
    required DateTime timestamp,
    this.latDeg,
    this.lonDeg,
    this.sogMps,
    this.stwMps,
    this.twsMps,
    this.twdDeg,
    this.polarTwsMps,
    this.polarTwaDeg,
  }) : timestamp = timestamp.toUtc();

  /// A minta pillanata (UTC).
  final DateTime timestamp;

  @override
  final double? latDeg;

  @override
  final double? lonDeg;

  @override
  final double? sogMps;

  /// A vízhez mért sebesség (STW) m/s-ben.
  final double? stwMps;

  @override
  final double? twsMps;

  /// A valós szélirány mediánja (`TWD(med)`) fokban, `[0, 360)`-ban.
  @override
  final double? twdDeg;

  /// A valós szélsebesség mediánja (`TWS(med)`) m/s-ben, a polárhoz.
  final double? polarTwsMps;

  /// A valós szélszög mediánja (`TWA(med)`) előjelesen, `(−180, 180]`-ban;
  /// a bal halz negatív.
  final double? polarTwaDeg;

  @override
  List<Object?> get props => [
    timestamp,
    latDeg,
    lonDeg,
    sogMps,
    stwMps,
    twsMps,
    twdDeg,
    polarTwsMps,
    polarTwaDeg,
  ];
}

/// Egy régi minta súlya másodpercben: a `polar.csv` lépésköze (ADR 0050
/// D6). A lefedettség és a polár mért ideje is ezzel számol.
const int legacySampleSeconds = 10;
