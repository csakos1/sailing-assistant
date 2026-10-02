import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_web/app/web_layout.dart';
import 'package:foretack_web/app/web_scroll_column.dart';

void main() {
  // Szeles ablak: az oszlop mindket oldalan 200 px ures sav van.
  const window = Size(1280, 800);
  const sideGap = (1280 - WebLayout.columnMaxWidth) / 2;

  Future<void> pumpColumn(WidgetTester tester) async {
    tester.view
      ..physicalSize = window
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WebScrollColumn(
            bottomPadding: 56,
            children: [
              for (var i = 0; i < 30; i++)
                SizedBox(key: ValueKey(i), height: 100, child: Text('$i')),
            ],
          ),
        ),
      ),
    );
  }

  double scrollOffset(WidgetTester tester) =>
      tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels;

  testWidgets('scrolls with the wheel outside the content column', (
    tester,
  ) async {
    // ARRANGE
    await pumpColumn(tester);

    // ACT: gorgo a bal ures savban, az oszlopon kivul.
    await tester.sendEventToBinding(
      const PointerScrollEvent(
        position: Offset(sideGap / 2, 400),
        scrollDelta: Offset(0, 300),
      ),
    );
    await tester.pump();

    // ASSERT
    expect(scrollOffset(tester), 300);
  });

  testWidgets('keeps every child in the centred column', (tester) async {
    // ACT
    await pumpColumn(tester);

    // ASSERT
    final child = find.byKey(const ValueKey(0));
    expect(tester.getSize(child).width, WebLayout.columnMaxWidth);
    expect(tester.getTopLeft(child).dx, sideGap);
  });
}
