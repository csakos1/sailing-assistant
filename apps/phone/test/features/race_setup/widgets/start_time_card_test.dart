import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/features/race_setup/widgets/start_time_card.dart';

Future<void> _pump(
  WidgetTester tester, {
  String? value,
  String? note,
  VoidCallback? onOpen,
  VoidCallback? onClear,
}) => tester.pumpWidget(
  MaterialApp(
    theme: foretackTheme,
    home: Scaffold(
      body: StartTimeCard(
        label: 'RAJT IDOPONTJA',
        emptyLabel: 'Nincs tervezett rajt',
        clearTooltip: 'Rajtido torlese',
        value: value,
        note: note,
        onOpen: onOpen ?? () {},
        onClear: onClear ?? () {},
      ),
    ),
  ),
);

void main() {
  testWidgets('shows the empty text and a chevron when empty', (tester) async {
    // ARRANGE & ACT
    await _pump(tester);

    // ASSERT
    expect(find.text('Nincs tervezett rajt'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    expect(find.byTooltip('Rajtido torlese'), findsNothing);
  });

  testWidgets('shows the value and a clear button when filled', (
    tester,
  ) async {
    // ARRANGE & ACT
    await _pump(tester, value: '2026. okt. 10. · 09:00');

    // ASSERT
    expect(find.text('2026. okt. 10. · 09:00'), findsOneWidget);
    expect(find.text('Nincs tervezett rajt'), findsNothing);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
    expect(find.byTooltip('Rajtido torlese'), findsOneWidget);
  });

  testWidgets('opens the picker on a tap on the card', (tester) async {
    // ARRANGE
    var opened = false;
    await _pump(tester, onOpen: () => opened = true);

    // ACT
    await tester.tap(find.text('RAJT IDOPONTJA'));

    // ASSERT
    expect(opened, isTrue);
  });

  testWidgets('clears without opening the picker', (tester) async {
    // ARRANGE
    var opened = false;
    var cleared = false;
    await _pump(
      tester,
      value: '2026. okt. 10. · 09:00',
      onOpen: () => opened = true,
      onClear: () => cleared = true,
    );

    // ACT
    await tester.tap(find.byTooltip('Rajtido torlese'));

    // ASSERT
    expect(cleared, isTrue);
    expect(opened, isFalse);
  });

  testWidgets('shows the note below the value', (tester) async {
    // ARRANGE & ACT
    await _pump(tester, value: '2026. okt. 10. · 09:00', note: 'Elmult');

    // ASSERT
    final valueBottom = tester
        .getBottomLeft(find.text('2026. okt. 10. · 09:00'))
        .dy;
    final noteTop = tester.getTopLeft(find.text('Elmult')).dy;
    expect(noteTop, greaterThan(valueBottom));
  });

  testWidgets('is at least 62 dp tall (33a)', (tester) async {
    // ARRANGE & ACT
    await _pump(tester);

    // ASSERT
    expect(
      tester.getSize(find.byType(StartTimeCard)).height,
      greaterThanOrEqualTo(62),
    );
  });
}
