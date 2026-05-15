import 'package:meta/meta.dart';
import 'package:shared/shared.dart';

/// Egy relatív szög egy referenciairányhoz képest, fokban, signed.
///
/// Immutable value object. A [degrees] tipikusan [-180, +180) tartományban
/// értelmes, ahol:
/// - 0 = előre (a referenciairánnyal megegyezően)
/// - pozitív = jobbra (starboard)
/// - negatív = balra (port)
/// - -180 = pontosan hátul (downwind, illetve 180°-os fordulás)
///
/// A referenciairányt **nem a típus, hanem a használati kontextus** adja
/// meg: az AWA a boat heading-hez képest, a courseCorrection az
/// `effectiveDirection`-höz képest, stb. Ezért az `Angle` — a `Bearing`-gel
/// ellentétben — nem hordoz reference enum-ot; egy típusszintű címke nem
/// védene tényleges hibák ellen, csak zajt adna.
///
/// Háromféle létrehozási mód, eltérő bizalmi szintekre:
///
/// - [Angle.new] (default const): nincs runtime validáció és nincs
///   normalize. Csak akkor használd, ha a hívó garantálja az
///   érvényességet (const literál, vagy belső, már normalize-zott adat).
/// - [Angle.checked]: programozói hibára szabott. NaN vagy ±infinity
///   esetén [ArgumentError]-t dob; egyéb értékeket [-180, +180)
///   tartományba normalize-zal.
/// - [Angle.tryFromDegrees]: untrusted bemenethez. NaN vagy ±infinity
///   esetén [Err]; egyéb értékeket normalize-zal.
///
/// **Normalize-stratégia**: `((degrees + 180) % 360) - 180`. A felső
/// szél kizárt, az alsó zárt, így +180° → -180°-ra normalize-zódik.
/// A UI rétegben a -180 mint "downwind/180°-os fordulás" abszolút
/// értékkel és iránybetűvel jeleníthető meg.
///
/// **FONTOS — aritmetikai operátorok DEFERRED.** Önállóan az [Angle]
/// jelenleg csak storage value object. A tervezett operátorok (unary
/// `-`, `+`, `-`) és a kapcsolódó `Bearing - Bearing = Angle` aritmetika
/// egy későbbi `feat(domain): add Angle arithmetic operators` commitban
/// kerülnek be, amikor az első use case (várhatóan
/// `CalculateCourseCorrection`) megkívánja. Ez egy ismert nyitott
/// elem, nem felejtődik el — a domain réteg use case-jei előtt
/// be kell kerülnie.
@immutable
class Angle {
  /// Default const konstruktor — nincs validáció, nincs normalize. Csak
  /// garantáltan normalize-zott input esetén használd (pl. const literál).
  const Angle({required this.degrees});

  /// Programozói hiba védőhálója: NaN vagy ±infinity esetén
  /// [ArgumentError]-t dob. Egyéb értékeket [-180, +180) tartományba
  /// normalize-zal.
  factory Angle.checked({required double degrees}) {
    final result = Angle.tryFromDegrees(degrees: degrees);
    return switch (result) {
      Ok(value: final angle) => angle,
      Err(error: final err) => throw ArgumentError(err.toString()),
    };
  }

  /// Untrusted bemenet biztonságos validációja. NaN vagy ±infinity esetén
  /// [Err]; egyéb értékeket [-180, +180) tartományba normalize-zal.
  static Result<Angle, AngleError> tryFromDegrees({required double degrees}) {
    if (!degrees.isFinite) {
      return Err(AngleNotFinite(value: degrees));
    }
    // ((d + 180) mod 360) - 180. A Dart `double % double` véges, pozitív
    // osztóra mindig non-negatív eredményt ad, így +180 → -180,
    // -180 → -180, 181 → -179, 360 → 0, -270 → +90, 540 → -180.
    final normalized = ((degrees + 180) % 360) - 180;
    return Ok(Angle(degrees: normalized));
  }

  /// A szög fokban, signed. Konstruktortól függően nem feltétlenül
  /// normalize-zott (lásd [Angle.new]).
  final double degrees;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Angle && other.degrees == degrees;

  @override
  int get hashCode => degrees.hashCode;

  @override
  String toString() => 'Angle(deg: $degrees)';
}

/// Az [Angle.tryFromDegrees] hibakód-típusa. Sealed, hogy a hívó
/// pattern matching-gel minden esetet kötelezően kezeljen.
@immutable
sealed class AngleError {
  /// Csak az [AngleNotFinite] subclass hívja.
  const AngleError();
}

/// A megadott érték NaN vagy ±infinity — nem véges számábrázolás.
@immutable
final class AngleNotFinite extends AngleError {
  /// Hibainfó: a bemeneti [value] (NaN vagy ±∞).
  const AngleNotFinite({required this.value});

  /// A bemeneti érték (NaN vagy ±infinity).
  final double value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AngleNotFinite && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'AngleNotFinite(value: $value)';
}
