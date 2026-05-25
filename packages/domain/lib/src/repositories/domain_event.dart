import 'package:domain/src/entities/wind_data.dart';
import 'package:domain/src/value_objects/bearing.dart';
import 'package:domain/src/value_objects/coordinate.dart';
import 'package:domain/src/value_objects/speed.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Domain szintű esemény — a data réteg a nyers NMEA mondatokból már
/// domain-típusra fordított adatot ad át.
///
/// Az `NmeaStream.events` ezt a sealed hierarchiát streameli; a 6.4
/// szerint öt leaf-re bomlik (szél / pozíció / heading / COG+SOG /
/// vízsebesség), amit az application réteg providerei route-olnak a
/// megfelelő állapotba. Minden leaf [Equatable] (tesztelhető equality
/// és stringify).
@immutable
sealed class DomainEvent extends Equatable {
  /// Az eseményt a [timestamp] időbélyeggel hozza létre.
  const DomainEvent(this.timestamp);

  /// Az esemény időbélyege (a leaf forrásától függően a mérés vagy a
  /// recept ideje).
  final DateTime timestamp;

  @override
  bool? get stringify => true;
}

/// Szél-snapshot a műszerből (MWV-R / MWV-T / MWD aggregálva).
///
/// A [timestamp] a [WindData]-é (nem külön paraméter), ezért a ctor nem
/// const.
class WindEvent extends DomainEvent {
  /// A [data] szél-snapshotból; a [timestamp] a `data.timestamp`.
  WindEvent(this.data) : super(data.timestamp);

  /// A szél-snapshot (látszó + true mezők, részleges adat-tűréssel).
  final WindData data;

  @override
  List<Object?> get props => [data, timestamp];
}

/// GPS-pozíció esemény (GGA / GLL / RMC mondatokból).
class PositionEvent extends DomainEvent {
  /// A [position] koordinátából, [timestamp] időbélyeggel.
  const PositionEvent(this.position, super.timestamp);

  /// A mért földrajzi pozíció.
  final Coordinate position;

  @override
  List<Object?> get props => [position, timestamp];
}

/// Iránytű-heading esemény (HDG mondatból).
///
/// A [heading] reference-e magneticNorth; a true headinggé alakítás a
/// WMM-réteg (Phase 2) feladata, nem ezé az eseményé.
class HeadingEvent extends DomainEvent {
  /// A [heading] iránnyal, [timestamp] időbélyeggel.
  const HeadingEvent(this.heading, super.timestamp);

  /// A mágneses heading (a `Bearing` hordozza a reference-ét).
  final Bearing heading;

  @override
  List<Object?> get props => [heading, timestamp];
}

/// Course Over Ground + Speed Over Ground együtt (RMC / VTG mondatokból).
class CogSogEvent extends DomainEvent {
  /// A [courseOverGround] és [speedOverGround] értékekkel, [timestamp]
  /// időbélyeggel.
  const CogSogEvent(
    this.courseOverGround,
    this.speedOverGround,
    super.timestamp,
  );

  /// Course Over Ground (trueNorth-referenciájú).
  final Bearing courseOverGround;

  /// Speed Over Ground.
  final Speed speedOverGround;

  @override
  List<Object?> get props => [courseOverGround, speedOverGround, timestamp];
}

/// Vízsebesség-esemény (VHW mondatból).
class SpeedEvent extends DomainEvent {
  /// A [speedThroughWater] értékkel, [timestamp] időbélyeggel.
  const SpeedEvent(this.speedThroughWater, super.timestamp);

  /// Speed Through Water (DST triducer).
  final Speed speedThroughWater;

  @override
  List<Object?> get props => [speedThroughWater, timestamp];
}

/// Műszer GPS-idő esemény (RMC UTC dátum+idő).
///
/// A [timestamp] maga a GPS-instant — nem a recept ideje —, mert a leaf
/// egyetlen feladata a hajó-műszer órájának továbbítása. A
/// `BoatStateProvider` (Phase 3) ebből tölti a `BoatState.instrumentTimeUtc`
/// mezőt; a `lastUpdate`-et viszont külön, az app-órából állítja.
class InstrumentTimeEvent extends DomainEvent {
  /// A [timestamp] a műszer UTC GPS-instantja (RMC dátum+idő).
  const InstrumentTimeEvent(super.timestamp);

  @override
  List<Object?> get props => [timestamp];
}
