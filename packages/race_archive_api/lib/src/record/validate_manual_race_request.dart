import 'package:meta/meta.dart';
import 'package:race_archive_api/src/record/manual_race_request.dart';
import 'package:race_archive_api/src/record/validate_manual_race_input.dart';
import 'package:race_archive_api/src/record/validate_race_result_input.dart';
import 'package:race_archive_api/src/validation/input_violation.dart';
import 'package:shared/shared.dart';

/// A kézi verseny teljes mentésének validációja: az alapadatok és az
/// eredmény együtt (ADR 0048 D6).
///
/// A két rész szabálysértései **egy listában** jönnek, előbb az
/// alapadatokéi, mert a szerkesztő is ebben a sorrendben mutatja a
/// mezőket, és a fókusz az első hibára ugrik (Addendum 1 G4).
@immutable
class ValidateManualRaceRequest {
  /// Állapotmentes validátor.
  const ValidateManualRaceRequest();

  static const ValidateManualRaceInput _validateRace =
      ValidateManualRaceInput();
  static const ValidateRaceResultInput _validateResult =
      ValidateRaceResultInput();

  /// A normalizált [request], vagy mindkét rész szabálysértései.
  Result<ManualRaceRequest, List<InputViolation>> call(
    ManualRaceRequest request,
  ) {
    final validatedRace = _validateRace(request.race);
    final validatedResult = _validateResult(request.result);
    return switch ((validatedRace, validatedResult)) {
      (Ok(value: final race), Ok(value: final result)) => Ok(
        ManualRaceRequest(race: race, result: result),
      ),
      _ => Err([
        ..._violationsOf(validatedRace),
        ..._violationsOf(validatedResult),
      ]),
    };
  }

  List<InputViolation> _violationsOf<T>(
    Result<T, List<InputViolation>> result,
  ) => switch (result) {
    Ok() => const [],
    Err(:final error) => error,
  };
}
