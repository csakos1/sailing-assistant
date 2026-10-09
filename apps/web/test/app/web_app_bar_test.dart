import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:foretack_web/app/web_app_bar.dart';

void main() {
  Future<void> pumpScrolledPage(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: foretackTheme,
        home: Scaffold(
          appBar: const WebAppBar(title: 'Versenynaplo'),
          body: ListView(
            children: [
              for (var i = 0; i < 40; i++)
                SizedBox(height: 56, child: Text('$i')),
            ],
          ),
        ),
      ),
    );
    // A lista gorgetese "scrolled under" allapotba tenne egy M3 AppBart.
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
  }

  Material appBarMaterial(WidgetTester tester) => tester.widget<Material>(
    find
        .descendant(of: find.byType(AppBar), matching: find.byType(Material))
        .first,
  );

  testWidgets('uses the year band colour, like the 13a header', (
    tester,
  ) async {
    // ACT
    await pumpScrolledPage(tester);

    // ASSERT
    expect(
      appBarMaterial(tester).color,
      foretackTheme.colorScheme.surfaceContainer,
    );
  });

  testWidgets('keeps a flat, untinted bar when content scrolls under it', (
    tester,
  ) async {
    // ACT
    await pumpScrolledPage(tester);

    // ASSERT
    final material = appBarMaterial(tester);
    expect(material.elevation, 0);
    expect(material.surfaceTintColor, Colors.transparent);
  });
}
