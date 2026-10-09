import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_web/api/api_failure.dart';
import 'package:foretack_web/race_edit/editor_problems.dart';
import 'package:foretack_web/race_edit/form/field_problem.dart';
import 'package:race_archive_api/race_archive_api.dart';

void main() {
  group('firstProblemInFormOrder', () {
    test('picks the problem highest on the screen, not the first listed', () {
      const ys = TextNotReadable(
        InputField.ysNumberHundredths,
        TextFormat.ysNumber,
      );
      const place = RuleBroken(PlaceExceedsFleetSize(InputField.classPlace));

      expect(firstProblemInFormOrder(const [ys, place]), place);
    });

    test('is null without problems', () {
      expect(firstProblemInFormOrder(const []), isNull);
    });
  });

  group('viewOfSaveFailure', () {
    test('shows server validation errors under the fields', () {
      final view = viewOfSaveFailure(
        const ServerFailure(
          ValidationFailed([ValueNotPositive(InputField.overallFleetSize)]),
        ),
      );

      expect(view.problems, const [
        RuleBroken(ValueNotPositive(InputField.overallFleetSize)),
      ]);
      expect(view.message, isNull);
    });

    test('names a race that is gone', () {
      final view = viewOfSaveFailure(
        const ServerFailure(RaceNotFound('r1')),
      );

      expect(view.message, SaveFailureMessage.raceGone);
    });

    test('falls back to a general message', () {
      expect(
        viewOfSaveFailure(const NetworkFailure('offline')).message,
        SaveFailureMessage.saveFailed,
      );
      expect(
        viewOfSaveFailure(const UnreadableResponse(502)).message,
        SaveFailureMessage.saveFailed,
      );
    });
  });
}
