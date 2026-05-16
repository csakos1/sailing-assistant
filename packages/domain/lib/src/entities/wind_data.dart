import 'package:domain/src/value_objects/angle.dart';
import 'package:domain/src/value_objects/bearing.dart';
import 'package:domain/src/value_objects/speed.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Egy időpillanatban érzékelt szél-snapshot.
///
/// Az NMEA 2000 PGN 130306 ("Wind Data") üzenetekből épül fel; a stream
/// különböző referencia-szintű PGN-eit a parser-réteg olvasztja egyetlen
/// WindData-vá:
///
/// - **apparentAngle / apparentSpeed** (AWA, AWS) — a mast-fej szenzor
///   közvetlen mérése; amíg a szenzor él, mindig elérhetők.
/// - **trueAngleWater / trueSpeedWater** (TWA-water, TWS-water) — a műszer
///   AWA + boat-speed-water (DST triducer) alapján számolja boat-frame-ben.
///   `null`, ha a DST szenzor inaktív, vagy a stream warm-up szakaszában
///   még nem érkezett meg.
/// - **trueDirectionGround** (TWD-ground) — abszolút szélirány a föld-frame-
///   ben; közvetlenül a PGN-ből vagy TWA-water + heading + currents
///   számításból. `null`, ha a hardver-konfiguráció nem szolgáltatja.
///
/// **A részleges adat tudatos design.** A hajón nem oldható meg menet
/// közben egy szenzor-hiba (algásodás, kábelszakadás, packet loss), ezért
/// a domain modell elfogadja a null-mezőket, és a részleges WindData így
/// is használható a UI-on és más use case-ekben. A hiány **láthatóságát**
/// a Warning rendszer (lásd ARCHITECTURE.md 11. szekció) biztosítja —
/// a `hasTrueWind` getter konkrétan ehhez a detektoráláshoz nyújt
/// belépési pontot.
@immutable
class WindData extends Equatable {
  const WindData({
    required this.apparentAngle,
    required this.apparentSpeed,
    required this.timestamp,
    this.trueAngleWater,
    this.trueSpeedWater,
    this.trueDirectionGround,
  });

  /// Apparent Wind Angle (AWA), signed. Mast-fej szenzor közvetlen mérése.
  final Angle apparentAngle;

  /// Apparent Wind Speed (AWS). Mast-fej szenzor közvetlen mérése.
  final Speed apparentSpeed;

  /// True Wind Angle (water-referenced), signed. Műszer-számolt érték
  /// boat-frame-ben. `null`, ha a true-wind számolás nem érhető el
  /// (jellemzően DST szenzor inaktív vagy stream warm-up).
  final Angle? trueAngleWater;

  /// True Wind Speed (water-referenced). Műszer-számolt érték. `null`, ha
  /// a true-wind számolás nem érhető el.
  final Speed? trueSpeedWater;

  /// True Wind Direction (ground-referenced), abszolút bearing. `null`,
  /// ha a hardver-konfiguráció nem szolgáltatja (direkten vagy számolt
  /// formában).
  final Bearing? trueDirectionGround;

  /// A snapshot időbélyege.
  final DateTime timestamp;

  /// Igaz, ha legalább egy true-wind mezőhöz (TWA-water, TWS-water vagy
  /// TWD-ground) van adat.
  ///
  /// A Warning-rendszer ezt használja arra, hogy a "true wind nem
  /// elérhető" jelzést kiváltsa — ha mindhárom hiányzik, valószínűleg
  /// szenzor- vagy konfigurációs probléma van.
  bool get hasTrueWind =>
      trueAngleWater != null ||
      trueSpeedWater != null ||
      trueDirectionGround != null;

  /// Immutable update. Simple-form: `null` = ne változtass az adott mezőn.
  ///
  /// Korlátozás: a copyWith nem tudja `null`-ra állítani az opcionális
  /// mezőket (TWA-water, TWS-water, TWD-ground) — ha egy snapshotban
  /// valami null, az új snapshot legyen új [WindData] instance.
  WindData copyWith({
    Angle? apparentAngle,
    Speed? apparentSpeed,
    Angle? trueAngleWater,
    Speed? trueSpeedWater,
    Bearing? trueDirectionGround,
    DateTime? timestamp,
  }) {
    return WindData(
      apparentAngle: apparentAngle ?? this.apparentAngle,
      apparentSpeed: apparentSpeed ?? this.apparentSpeed,
      trueAngleWater: trueAngleWater ?? this.trueAngleWater,
      trueSpeedWater: trueSpeedWater ?? this.trueSpeedWater,
      trueDirectionGround: trueDirectionGround ?? this.trueDirectionGround,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  List<Object?> get props => [
    apparentAngle,
    apparentSpeed,
    trueAngleWater,
    trueSpeedWater,
    trueDirectionGround,
    timestamp,
  ];

  @override
  bool? get stringify => true;
}
