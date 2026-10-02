import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_web/app/leave_warning_provider.dart';
import 'package:foretack_web/app/leave_warning_scope.dart';

void main() {
  testWidgets('holds its condition only while it is in the tree', (
    tester,
  ) async {
    // ARRANGE
    final container = ProviderContainer();
    addTearDown(container.dispose);
    var isDirty = true;

    Future<void> pump({required bool isShown}) => tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: isShown
            ? LeaveWarningScope(
                shouldWarn: () => isDirty,
                child: const SizedBox(),
              )
            : const SizedBox(),
      ),
    );

    // ACT
    await pump(isShown: true);

    // ASSERT
    final registry = container.read(leaveWarningProvider);
    expect(registry.shouldWarn, isTrue);
    isDirty = false;
    expect(registry.shouldWarn, isFalse);

    // ACT
    isDirty = true;
    await pump(isShown: false);

    // ASSERT
    expect(registry.shouldWarn, isFalse);
  });
}
