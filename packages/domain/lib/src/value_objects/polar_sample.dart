import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Egy pillanatkép polár-projekciója (ADR 0049 D13, Addendum 3 T1).
///
/// A `WindSample` mintájára keskeny szerződés: a polár-teljesítményhez a
/// szélszög, a szélsebesség és a vízsebesség kell, az időbélyeggel. A
/// mérések `null`-képesek, mert a műszer nem mindig adja őket.
///
/// A [durationSeconds] azt mondja meg, hány másodpercet ér a minta a
/// hisztogramban és a mért időben: a telefon 1 Hz-es pillanatképe 1, a
/// régi fedélzeti napló 10 másodperces mintája 10 (ADR 0050 D6).
@immutable
class PolarSample extends Equatable {
  /// Minta a [timestamp] pillanatban.
  PolarSample({
    required DateTime timestamp,
    this.twaDeg,
    this.twsMps,
    this.stwMps,
    this.durationSeconds = 1,
  }) : timestamp = timestamp.toUtc(),
       assert(durationSeconds > 0, 'A minta súlya pozitív.');

  /// A minta pillanata (UTC).
  final DateTime timestamp;

  /// A valós szélszög (víz-referenciás) fokban, előjelesen: bal − ,
  /// jobb +.
  final double? twaDeg;

  /// A valós szélsebesség (víz-referenciás) m/s-ben.
  final double? twsMps;

  /// A vízsebesség (STW) m/s-ben, korrekció nélkül.
  final double? stwMps;

  /// Hány másodpercet ér a minta.
  final int durationSeconds;

  @override
  List<Object?> get props => [
    timestamp,
    twaDeg,
    twsMps,
    stwMps,
    durationSeconds,
  ];
}
