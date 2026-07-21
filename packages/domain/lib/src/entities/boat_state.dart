import 'package:domain/src/value_objects/bearing.dart';
import 'package:domain/src/value_objects/coordinate.dart';
import 'package:domain/src/value_objects/depth.dart';
import 'package:domain/src/value_objects/speed.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// A hajó pillanatnyi állapotának snapshot-je az NMEA-stream alapján.
///
/// Minden adat-mező opcionális — egyetlen kötelező a [lastUpdate]
/// időbélyeg. A részleges adat ugyanazon logika alapján engedett, mint a
/// `WindData`-nál: stream warm-up, szenzor-hiba, packet loss esetén a
/// részleges állapot is használható, és a Warning rendszer
/// (ARCHITECTURE.md 11.) jelzi a hiányokat a UI-on.
///
/// **Bearing-reference invariánsok.** A három [Bearing] mező mindegyike
/// egy konkrét referencia-rendszert (true vagy magnetic north) képvisel,
/// és ezt asserttel ellenőrizzük a konstruktorban. Ez egy parser-szintű
/// hibatípust kap el (rossz reference enum-mal létrehozott Bearing) még
/// fejlesztés alatt:
///
/// - [headingMagnetic] → [BearingReference.magneticNorth]
/// - [headingTrue] → [BearingReference.trueNorth]
/// - [courseOverGround] → [BearingReference.trueNorth] (GPS COG mindig
///   abszolút északra mért)
@immutable
class BoatState extends Equatable {
  BoatState({
    required this.lastUpdate,
    this.position,
    this.headingMagnetic,
    this.headingTrue,
    this.courseOverGround,
    this.speedOverGround,
    this.speedThroughWater,
    this.depth,
    this.instrumentTimeUtc,
  }) : assert(
         headingMagnetic == null ||
             headingMagnetic.reference == BearingReference.magneticNorth,
         'headingMagnetic mező magneticNorth-referenciájú Bearing-et '
         'tárol.',
       ),
       assert(
         headingTrue == null ||
             headingTrue.reference == BearingReference.trueNorth,
         'headingTrue mező trueNorth-referenciájú Bearing-et tárol.',
       ),
       assert(
         courseOverGround == null ||
             courseOverGround.reference == BearingReference.trueNorth,
         'courseOverGround mező trueNorth-referenciájú Bearing-et tárol '
         '(a GPS COG abszolút északra mért).',
       );

  /// A hajó utolsó ismert pozíciója. `null`, ha még nem jött pozíció-PGN.
  final Coordinate? position;

  /// Mágneses heading a műszerről (pl. ZG100). `null`, ha nincs adat.
  final Bearing? headingMagnetic;

  /// Geográfiai (true) heading. v1-ben a műszer által a `HDG`-ben közölt
  /// mágneses variációból (E/W) áll elő (`magnetic + variation`); a teljes
  /// WMM-modell v2-fallback (ADR 0013). `null`, ha a variáció hiányzik.
  final Bearing? headingTrue;

  /// Course Over Ground (GPS). Abszolút északra mért irány.
  final Bearing? courseOverGround;

  /// Speed Over Ground (GPS).
  final Speed? speedOverGround;

  /// Speed Through Water (DST triducer).
  final Speed? speedThroughWater;

  /// A víz mélysége a jeladó alatt, offset nélkül (ADR 0031 D2). `null`,
  /// amíg nem jött használható `DPT`/`DBT` mondat.
  final Depth? depth;

  /// A snapshot időbélyege (utolsó stream-frissítés).
  final DateTime lastUpdate;

  /// A hajó GPS-műszere szerinti pontos idő UTC-ben (az `RMC` dátum+idő
  /// mezőiből), hogy a watch a chartplotterrel egyező időt mutathasson.
  ///
  /// **Tudatosan külön a [lastUpdate]-től:** az utóbbi az app órája az
  /// utolsó stream-frissítéskor (receipt-idő, latency-vel terhelt, és
  /// akkor is ketyeg, ha az `RMC` elnémul), míg ez a műszer által közölt
  /// instant. A domain UTC-ben tárolja az igazságot; a megjelenítési
  /// időzóna presentation-réteg döntés (ARCHITECTURE.md 10.4). Friss
  /// `RMC`-idő hiányában `null`, és a UI stale-jelzést ad (11.).
  final DateTime? instrumentTimeUtc;

  /// A hajó valós haladási iránya: COG ha érdemben mozgunk, különben a
  /// műszer által mért true heading.
  ///
  /// Logika:
  /// - Ha SOG > 1.5 csomó (≈ 0.7717 m/s) **és** COG ismert → COG.
  /// - Egyébként ha [headingTrue] ismert → [headingTrue].
  /// - Egyébként null.
  ///
  /// A küszöb alatt a GPS-noise dominálja a COG-t (kis elmozdulásokon a
  /// numerikus zaj a domináns jel), ezért inkább a műszer által mért
  /// orientációt használjuk.
  ///
  /// **A return mindig [BearingReference.trueNorth]-referenciájú vagy
  /// null.** A [headingMagnetic]-re tudatosan nem fall-backelünk: a true
  /// heading a HDG-variációból (v1) vagy a WMM-ből (v2) áll elő; ha egyik
  /// sem elérhető, a downstream számításokba (course correction,
  /// bearing-to-mark)
  /// inkonzisztens reference kerülne. Inkább null, mint csendes hiba.
  Bearing? get effectiveDirection {
    // 1.5 csomó ≈ 0.7717 m/s. Az "érdemi mozgás" küszöbe.
    const cogThreshold = Speed(metersPerSecond: 0.7717);
    final sog = speedOverGround;
    final cog = courseOverGround;
    if (sog != null &&
        cog != null &&
        sog.metersPerSecond > cogThreshold.metersPerSecond) {
      return cog;
    }
    return headingTrue;
  }

  /// Immutable update. Simple-form: `null` = ne változtass az adott
  /// mezőn. Az opcionális mezők null-ra állításához új [BoatState] kell.
  BoatState copyWith({
    Coordinate? position,
    Bearing? headingMagnetic,
    Bearing? headingTrue,
    Bearing? courseOverGround,
    Speed? speedOverGround,
    Speed? speedThroughWater,
    Depth? depth,
    DateTime? lastUpdate,
    DateTime? instrumentTimeUtc,
  }) {
    return BoatState(
      position: position ?? this.position,
      headingMagnetic: headingMagnetic ?? this.headingMagnetic,
      headingTrue: headingTrue ?? this.headingTrue,
      courseOverGround: courseOverGround ?? this.courseOverGround,
      speedOverGround: speedOverGround ?? this.speedOverGround,
      speedThroughWater: speedThroughWater ?? this.speedThroughWater,
      depth: depth ?? this.depth,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      instrumentTimeUtc: instrumentTimeUtc ?? this.instrumentTimeUtc,
    );
  }

  @override
  List<Object?> get props => [
    position,
    headingMagnetic,
    headingTrue,
    courseOverGround,
    speedOverGround,
    speedThroughWater,
    depth,
    lastUpdate,
    instrumentTimeUtc,
  ];

  @override
  bool? get stringify => true;
}
