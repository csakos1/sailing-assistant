import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/features/web_access/presentation/widgets/web_action_button.dart';

void main() {
  Future<void> pumpButton(WidgetTester tester, Widget button) =>
      tester.pumpWidget(
        MaterialApp(
          theme: foretackTheme,
          home: Scaffold(body: Center(child: button)),
        ),
      );

  double opacityOf(WidgetTester tester) => tester
      .widget<Opacity>(
        find.descendant(
          of: find.byType(WebActionButton),
          matching: find.byType(Opacity),
        ),
      )
      .opacity;

  testWidgets('both kinds are 48 px tall with square corners', (
    tester,
  ) async {
    // Arrange
    await pumpButton(
      tester,
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          WebActionButton.primary(label: 'Újra', onPressed: () {}),
          WebActionButton.secondary(label: 'Bezárás', onPressed: () {}),
        ],
      ),
    );

    // Act
    final primary = tester.widget<FilledButton>(find.byType(FilledButton));
    final secondary = tester.widget<OutlinedButton>(
      find.byType(OutlinedButton),
    );

    // Assert
    expect(tester.getSize(find.byType(FilledButton)).height, 48);
    expect(tester.getSize(find.byType(OutlinedButton)).height, 48);
    expect(
      primary.style?.shape?.resolve(const {}),
      const RoundedRectangleBorder(),
    );
    expect(
      secondary.style?.shape?.resolve(const {}),
      const RoundedRectangleBorder(),
    );
  });

  testWidgets('a disabled button fades to 35 percent', (tester) async {
    // Act
    await pumpButton(
      tester,
      const WebActionButton.primary(label: 'Kérelem küldése', onPressed: null),
    );

    // Assert
    expect(opacityOf(tester), WebActionButton.disabledOpacity);
  });

  testWidgets('a busy button spins, ignores taps and does not fade', (
    tester,
  ) async {
    // Arrange
    var taps = 0;
    await pumpButton(
      tester,
      WebActionButton.primary(
        label: 'Kérelem küldése',
        isBusy: true,
        onPressed: () => taps++,
      ),
    );

    // Act
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    // Assert
    expect(taps, 0);
    expect(opacityOf(tester), 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Kérelem küldése'), findsNothing);
  });

  testWidgets('the destructive button has an error border', (tester) async {
    // Arrange
    await pumpButton(
      tester,
      WebActionButton.destructive(label: 'Kiléptetés', onPressed: () {}),
    );
    final context = tester.element(find.byType(WebActionButton));

    // Act
    final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));

    // Assert
    expect(
      button.style?.side?.resolve(const {})?.color,
      Theme.of(context).colorScheme.error,
    );
  });

  testWidgets('the compact button is 40 px tall', (tester) async {
    // Act
    await pumpButton(
      tester,
      WebActionButton.secondary(
        label: 'Rendben',
        isCompact: true,
        onPressed: () {},
      ),
    );

    // Assert
    expect(tester.getSize(find.byType(OutlinedButton)).height, 40);
  });
}
