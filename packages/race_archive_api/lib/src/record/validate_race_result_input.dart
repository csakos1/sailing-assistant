import 'package:meta/meta.dart';
import 'package:race_archive_api/src/record/placing.dart';
import 'package:race_archive_api/src/record/race_result_input.dart';
import 'package:race_archive_api/src/validation/input_field.dart';
import 'package:race_archive_api/src/validation/input_violation.dart';
import 'package:race_archive_api/src/validation/trimmed_or_null.dart';
import 'package:shared/shared.dart';

/// Az eredmény validációja és normalizálása (ADR 0048 D3 + Addendum 2 H5).
///
/// Pure: a szerver mentés előtt, a web űrlapja a mentés gombra hívja,
/// ugyanazzal az eredménnyel. **Minden** szabálysértést visszaad, hogy az
/// űrlap minden hibás mezőt egyszerre jelezzen.
///
/// Szabályok:
///  - a számszerű helyezés, a mezőny és a YS-szám legalább 1;
///  - **páronként**: ha a számszerű helyezés és a saját mezőnye is megvan,
///    a helyezés nem nagyobb (a hiba a helyezés mezőjéhez kötődik). DNF és
///    DSQ mellett a mezőny szabadon megadható;
///  - ha mindkét hivatalos idő megvan, a befutás később van a rajtnál;
///  - a díj és az összefoglaló széleiről levágjuk a whitespace-t, az üres
///    `null` lesz; az időket UTC-re normáljuk.
@immutable
class ValidateRaceResultInput {
  /// Állapotmentes validátor.
  const ValidateRaceResultInput();

  /// A normalizált [input], vagy a szabálysértések listája.
  Result<RaceResultInput, List<InputViolation>> call(RaceResultInput input) {
    final violations = <InputViolation>[
      ..._checkPlacingPair(
        placing: input.classPlace,
        fleetSize: input.classFleetSize,
        placeField: InputField.classPlace,
        fleetSizeField: InputField.classFleetSize,
      ),
      ..._checkPlacingPair(
        placing: input.overallPlace,
        fleetSize: input.overallFleetSize,
        placeField: InputField.overallPlace,
        fleetSizeField: InputField.overallFleetSize,
      ),
      ..._checkPlacingPair(
        placing: input.monohullPlace,
        fleetSize: input.monohullFleetSize,
        placeField: InputField.monohullPlace,
        fleetSizeField: InputField.monohullFleetSize,
      ),
      if (input.ysNumberHundredths case final ys? when ys < 1)
        const ValueNotPositive(InputField.ysNumberHundredths),
      if (_isFinishNotAfterStart(input)) const FinishNotAfterStart(),
    ];
    if (violations.isNotEmpty) return Err(violations);
    return Ok(_normalized(input));
  }

  List<InputViolation> _checkPlacingPair({
    required Placing? placing,
    required int? fleetSize,
    required InputField placeField,
    required InputField fleetSizeField,
  }) {
    final place = switch (placing) {
      FinishPlace(:final place) => place,
      _ => null,
    };
    final violations = <InputViolation>[
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

  bool _isFinishNotAfterStart(RaceResultInput input) =>
      switch ((input.officialStart, input.officialFinish)) {
        (final DateTime start, final DateTime finish) => !finish.isAfter(start),
        _ => false,
      };

  RaceResultInput _normalized(RaceResultInput input) => RaceResultInput(
    classPlace: input.classPlace,
    classFleetSize: input.classFleetSize,
    overallPlace: input.overallPlace,
    overallFleetSize: input.overallFleetSize,
    monohullPlace: input.monohullPlace,
    monohullFleetSize: input.monohullFleetSize,
    ysNumberHundredths: input.ysNumberHundredths,
    officialStart: input.officialStart?.toUtc(),
    officialFinish: input.officialFinish?.toUtc(),
    prize: trimmedOrNull(input.prize),
    summary: trimmedOrNull(input.summary),
  );
}
