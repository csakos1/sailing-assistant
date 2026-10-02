import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_web/app/leave_warning_registry.dart';

void main() {
  group('LeaveWarningRegistry', () {
    test('does not warn without any condition', () {
      expect(LeaveWarningRegistry().shouldWarn, isFalse);
    });

    test('asks the conditions at the moment of leaving', () {
      // ARRANGE
      final registry = LeaveWarningRegistry();
      var isDirty = false;
      registry.hold(() => isDirty);

      // ACT + ASSERT
      expect(registry.shouldWarn, isFalse);
      isDirty = true;
      expect(registry.shouldWarn, isTrue);
    });

    test('warns when any one condition holds', () {
      // ARRANGE
      final registry = LeaveWarningRegistry()
        ..hold(() => false)
        ..hold(() => true);

      // ACT + ASSERT
      expect(registry.shouldWarn, isTrue);
    });

    test('releases exactly the condition it was given back for', () {
      // ARRANGE: ket egyforma tear-off, egyik sem vihet el mast
      final registry = LeaveWarningRegistry();
      bool alwaysWarn() => true;
      final releaseFirst = registry.hold(alwaysWarn);
      final releaseSecond = registry.hold(alwaysWarn);

      // ACT
      releaseFirst();

      // ASSERT
      expect(registry.shouldWarn, isTrue);
      releaseSecond();
      expect(registry.shouldWarn, isFalse);
    });
  });
}
