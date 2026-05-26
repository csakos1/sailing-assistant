import 'package:domain/domain.dart';
import 'package:meta/meta.dart';

/// A szél-mondat referenciakerete (MWV R/T flag).
///
/// `apparent` = a hajóhoz képest mért látszólagos szél (MWV `R`);
/// `true_` = a Vulcan által számolt valódi szél (MWV `T`).
enum WindReference { apparent, true_ }

/// Egy tipizált, dekódolt NMEA 0183 mondat.
///
/// A `SentenceDecoder` (ARCHITECTURE.md 6.3) állítja elő a nyers
/// `Sentence`-ből; a mapper (6.4) alakítja `DomainEvent`(ek)re. Sealed,
/// hogy a mapper exhaustive `switch`-csel minden ágat kötelezően kezeljen.
@immutable
sealed class DecodedSentence {
  /// Csak a leaf subclass-ok hívják.
  const DecodedSentence();
}

/// Apparent vagy true szél (MWV); a [reference] dönti el, melyik.
final class DecodedWind extends DecodedSentence {
  /// Dekódolt szél-mondatot csomagol.
  const DecodedWind({
    required this.reference,
    required this.angle,
    required this.speed,
  });

  /// Apparent (MWV `R`) vagy true (MWV `T`) referencia.
  final WindReference reference;

  /// Szél-szög a hajó orrához képest, signed `[-180, +180)`.
  final Angle angle;

  /// Szélsebesség m/s-ban (a wire-egységet a dekóder váltja át).
  final Speed speed;
}

/// A valódi szélirány (MWD) — ground-referenciás TWD + szélsebesség.
final class DecodedWindDirection extends DecodedSentence {
  /// Dekódolt szélirány-mondatot csomagol.
  const DecodedWindDirection({required this.direction, required this.speed});

  /// A valódi szélirány (TWD), trueNorth-referenciás `[0, 360)`.
  final Bearing direction;

  /// Szélsebesség m/s-ban.
  final Speed speed;
}

/// Az `RMC` kompozit mondat: pozíció + COG/SOG + GPS-időbélyeg egyben.
///
/// A mapper (6.4) bontja `PositionEvent` + `CogSogEvent` +
/// `InstrumentTimeEvent`-re; a [timestampUtc] az NMEA GPS-instantja
/// (nem az app-óra).
final class DecodedRmc extends DecodedSentence {
  /// Dekódolt RMC mondatot csomagol.
  const DecodedRmc({
    required this.position,
    required this.courseOverGround,
    required this.speedOverGround,
    required this.timestampUtc,
  });

  /// A hajó pozíciója (WGS84).
  final Coordinate position;

  /// Menetirány a talaj felett (COG), trueNorth-referenciás `[0, 360)`.
  final Bearing courseOverGround;

  /// Sebesség a talaj felett (SOG), m/s.
  final Speed speedOverGround;

  /// A GPS-fix UTC-időbélyege (instrument-óra, nem app-óra).
  final DateTime timestampUtc;
}

/// A `VTG` mondat: menetirány és sebesség a talaj felett (COG/SOG).
///
/// A v1 a true COG-ot (field 0, trueNorth) és a csomóból m/s-ra váltott
/// SOG-ot (field 4) veszi; a mágneses COG és a km/h-érték redundáns
/// (ARCHITECTURE.md 6.3). A mapper (6.4) `CogSogEvent`-re alakítja.
final class DecodedCogSog extends DecodedSentence {
  /// Dekódolt COG/SOG mondatot csomagol.
  const DecodedCogSog({
    required this.courseOverGround,
    required this.speedOverGround,
  });

  /// Menetirány a talaj felett (COG), trueNorth-referenciás `[0, 360)`.
  final Bearing courseOverGround;

  /// Sebesség a talaj felett (SOG), m/s.
  final Speed speedOverGround;
}

/// A pozíció-fix (GGA / GLL) — csak a WGS84 koordináta.
///
/// A GGA és a GLL is redundánsan adja a pozíciót (az RMC mellett); a
/// provider a legfrissebbet tartja (ARCHITECTURE.md 6.6). A mapper (6.4)
/// `PositionEvent`-re alakítja.
final class DecodedPosition extends DecodedSentence {
  /// Dekódolt pozíció-mondatot csomagol.
  const DecodedPosition({required this.position});

  /// A hajó pozíciója (WGS84).
  final Coordinate position;
}

/// A mágneses heading (HDG) — a hajó orrának iránya.
///
/// A v1 csak a mágneses headinget veszi; a true heading a WMM-deklinációval
/// áll elő a domainben (ARCHITECTURE.md 6.5). A mapper (6.4)
/// `HeadingEvent`-re alakítja.
final class DecodedHeading extends DecodedSentence {
  /// Dekódolt heading-mondatot csomagol.
  const DecodedHeading({required this.heading});

  /// A hajó orrának iránya, magneticNorth-referenciás `[0, 360)`.
  final Bearing heading;
}

/// A vízhez viszonyított sebesség (VHW) — speed through water (STW).
///
/// A v1 csak az STW-t veszi a VHW-ből (a talaj-sebesség, SOG, az RMC/VTG-ből
/// jön, a heading a HDG-ből). A mapper (6.4) `SpeedEvent`-re alakítja.
final class DecodedSpeed extends DecodedSentence {
  /// Dekódolt STW-mondatot csomagol.
  const DecodedSpeed({required this.speedThroughWater});

  /// A hajó sebessége a vízhez képest (STW), m/s.
  final Speed speedThroughWater;
}
