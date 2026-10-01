import 'package:meta/meta.dart';
import 'package:race_archive_api/src/annotation/annotation_violation.dart';
import 'package:race_archive_api/src/annotation/race_annotation_input.dart';
import 'package:race_archive_api/src/validation/input_violation.dart';
import 'package:shared/shared.dart';

/// Az eredmény-adatok validációja és normalizálása (ADR 0047 Addendum 1
/// A6).
///
/// Pure: a szerver mentés előtt, a web űrlapja a mentés gombra hívja,
/// ugyanazzal az eredménnyel. **Minden** szabálysértést visszaad, hogy az
/// űrlap minden hibás mezőt egyszerre jelezzen.
///
/// Szabályok:
///  - a megadott helyezés és mezőny legalább 1;
///  - ha a helyezés és a mezőny is megvan, a helyezés nem nagyobb a
///    mezőnynél (a hiba a helyezés mezőjéhez kötődik);
///  - az összefoglaló széleiről levágjuk a whitespace-t, és ha így üres,
///    `null` lesz.
@immutable
class ValidateRaceAnnotationInput {
  /// Állapotmentes validátor.
  const ValidateRaceAnnotationInput();

  /// A normalizált [input], vagy a szabálysértések listája.
  Result<RaceAnnotationInput, List<AnnotationViolation>> call(
    RaceAnnotationInput input,
  ) {
    final violations = <AnnotationViolation>[
      ..._checkPlacePair(
        place: input.overallPlace,
        fleetSize: input.overallFleetSize,
        placeField: AnnotationField.overallPlace,
        fleetSizeField: AnnotationField.overallFleetSize,
      ),
      ..._checkPlacePair(
        place: input.classPlace,
        fleetSize: input.classFleetSize,
        placeField: AnnotationField.classPlace,
        fleetSizeField: AnnotationField.classFleetSize,
      ),
    ];
    if (violations.isNotEmpty) return Err(violations);

    final summary = input.summary?.trim();
    return Ok(
      RaceAnnotationInput(
        overallPlace: input.overallPlace,
        overallFleetSize: input.overallFleetSize,
        classPlace: input.classPlace,
        classFleetSize: input.classFleetSize,
        summary: summary == null || summary.isEmpty ? null : summary,
      ),
    );
  }

  List<AnnotationViolation> _checkPlacePair({
    required int? place,
    required int? fleetSize,
    required AnnotationField placeField,
    required AnnotationField fleetSizeField,
  }) {
    final violations = <AnnotationViolation>[
      if (place != null && place < 1) ValueNotPositive(placeField),
      if (fleetSize != null && fleetSize < 1) ValueNotPositive(fleetSizeField),
    ];
    // A sorrend-szabály csak két érvényes számra értelmes: egy nem pozitív
    // érték mellé nem adunk egy második, félrevezető hibát.
    if (violations.isEmpty &&
        place != null &&
        fleetSize != null &&
        place > fleetSize) {
      violations.add(PlaceExceedsFleetSize(placeField));
    }
    return violations;
  }
}
