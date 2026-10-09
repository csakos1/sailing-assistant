import 'package:meta/meta.dart';
import 'package:race_archive_api/src/record/manual_race_input.dart';
import 'package:race_archive_api/src/validation/input_field.dart';
import 'package:race_archive_api/src/validation/input_violation.dart';
import 'package:shared/shared.dart';

/// A kézi verseny alapadatainak validációja és normalizálása (ADR 0048
/// D6, Addendum 2 H5).
///
/// Pure, és minden szabálysértést egyszerre ad vissza. A dátum és az égtáj
/// érvényességét már a dekódolás biztosítja, itt csak a tartalom számít.
///
/// Szabályok:
///  - a név a szélei levágása után nem üres (a normalizált név a levágott);
///  - a táv, a sebesség és a szél nem negatív. A nulla megengedett: a
///    szélcsendes nap is adat.
@immutable
class ValidateManualRaceInput {
  /// Állapotmentes validátor.
  const ValidateManualRaceInput();

  /// A normalizált [input], vagy a szabálysértések listája.
  Result<ManualRaceInput, List<InputViolation>> call(ManualRaceInput input) {
    final name = input.name.trim();
    final violations = <InputViolation>[
      if (name.isEmpty) const ValueEmpty(InputField.name),
      ..._checkNotNegative(input.distanceMeters, InputField.distanceMeters),
      ..._checkNotNegative(input.maxSpeedMps, InputField.maxSpeedMps),
      ..._checkNotNegative(input.avgWindMps, InputField.avgWindMps),
      ..._checkNotNegative(input.maxWindMps, InputField.maxWindMps),
    ];
    if (violations.isNotEmpty) return Err(violations);
    return Ok(
      ManualRaceInput(
        name: name,
        date: input.date,
        distanceMeters: input.distanceMeters,
        maxSpeedMps: input.maxSpeedMps,
        avgWindMps: input.avgWindMps,
        maxWindMps: input.maxWindMps,
        windPoint: input.windPoint,
      ),
    );
  }

  List<InputViolation> _checkNotNegative(double? value, InputField field) => [
    if (value != null && value < 0) ValueNegative(field),
  ];
}
