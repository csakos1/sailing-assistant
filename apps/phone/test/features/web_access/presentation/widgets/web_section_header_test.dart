import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/features/web_access/presentation/widgets/web_section_header.dart';

void main() {
  // 412 px-es telefon-nezet, mint a kezelokepernyok tesztjeiben.
  Future<void> pumpHeader(WidgetTester tester, Widget header) async {
    tester.view
      ..physicalSize = const Size(412, 915)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: foretackTheme,
        home: Scaffold(body: Column(children: [header])),
      ),
    );
  }

  testWidgets('the line runs to the count at the right margin', (
    tester,
  ) async {
    // Act
    await pumpHeader(tester, const WebSectionHeader(label: 'TAGOK', count: 4));

    // Assert
    final line = tester.getRect(find.byType(Divider));
    final count = tester.getRect(find.text('4'));
    expect(count.right, 392);
    expect(line.right, count.left - 10);
    expect(line.left, tester.getRect(find.text('TAGOK')).right + 10);
  });

  testWidgets('without a count the line stops 10 px before the margin', (
    tester,
  ) async {
    // Act
    await pumpHeader(tester, const WebSectionHeader(label: 'NÉV'));

    // Assert
    expect(tester.getRect(find.byType(Divider)).right, 382);
  });

  testWidgets('a long label is cut and still leaves a line', (tester) async {
    // Act
    await pumpHeader(
      tester,
      WebSectionHeader(label: 'A' * 60, count: 2),
    );

    // Assert
    expect(tester.takeException(), isNull);
    expect(tester.getRect(find.byType(Divider)).width, greaterThan(0));
  });
}
