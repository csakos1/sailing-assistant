import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/app/foretack_typography.dart';
import 'package:phone/app/text_tones.dart';
import 'package:phone/app/theme.dart';
import 'package:phone/features/race_detail/widgets/detail_mark_row.dart';

void main() {
  const single = Mark(
    sequence: 3,
    name: 'Szemes',
    position: Coordinate(latitude: 46.9, longitude: 18.05),
  );
  const twoDigit = Mark(
    sequence: 12,
    name: 'Boglari palya E',
    position: Coordinate(latitude: 46.712, longitude: 17.8555),
  );

  Future<void> pumpRow(
    WidgetTester tester,
    Mark mark, {
    bool isActive = false,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: foretackTheme,
        home: Scaffold(
          body: DetailMarkRow(mark: mark, isActive: isActive),
        ),
      ),
    );
  }

  Finder coloredBoxWith(Color color) => find.byWidgetPredicate(
    (widget) => widget is ColoredBox && widget.color == color,
  );

  TextStyle styleOf(WidgetTester tester, String text) =>
      tester.widget<Text>(find.text(text)).style!;

  testWidgets('pads a single digit ordinal to two', (tester) async {
    // ARRANGE & ACT
    await pumpRow(tester, single);

    // ASSERT
    expect(find.text('03'), findsOneWidget);
  });

  testWidgets('leaves a two digit ordinal alone', (tester) async {
    // ARRANGE & ACT
    await pumpRow(tester, twoDigit);

    // ASSERT - a toltes nem vag es nem is nyujt tovabb.
    expect(find.text('12'), findsOneWidget);
  });

  testWidgets('keeps the decimal degree coordinate format', (tester) async {
    // ARRANGE & ACT
    await pumpRow(tester, single);

    // ASSERT - ADR 0044 D25: a mai formatumhoz nem nyulunk.
    expect(find.text('46.9000, 18.0500'), findsOneWidget);
  });

  testWidgets('starts the ordinal at 20 dp in both states', (tester) async {
    // ARRANGE & ACT
    await pumpRow(tester, single);
    final inactive = tester.getTopLeft(find.text('03')).dx;
    await pumpRow(tester, single, isActive: true);
    final active = tester.getTopLeft(find.text('03')).dx;

    // ASSERT - 4 dp el-sav helye + 16 dp padding, allapottol fuggetlenul:
    // az el-sav helye kiemeles nelkul is fennmarad.
    expect(inactive, 20);
    expect(active, inactive);
  });

  testWidgets('paints the edge strip only for the active mark', (tester) async {
    // ARRANGE & ACT
    await pumpRow(tester, single);

    // ASSERT
    final scheme = foretackTheme.colorScheme;
    expect(coloredBoxWith(scheme.primary), findsNothing);
    expect(coloredBoxWith(scheme.outlineVariant), findsOneWidget);

    // ACT
    await pumpRow(tester, single, isActive: true);

    // ASSERT
    expect(coloredBoxWith(scheme.primary), findsOneWidget);
  });

  testWidgets('separates the mark name from the race name grade', (
    tester,
  ) async {
    // ARRANGE & ACT
    await pumpRow(tester, single);

    // ASSERT - a boja neve alarendelt a versenynek, tehat kisebb fokozat;
    // ha valaki ujrahasznalna a lajstrom-sor fokozatat, ez bukik.
    final nameStyle = styleOf(tester, 'Szemes');
    expect(nameStyle.fontSize, isNot(listItemTitleStyle.fontSize));
    expect(nameStyle.fontSize, greaterThan(numeralCaptionStyle.fontSize!));
  });

  testWidgets('mutes the ordinal and the coordinate', (tester) async {
    // ARRANGE & ACT
    await pumpRow(tester, single);

    // ASSERT
    // A foretackTheme regisztralja a TextTones-t, tehat sosem null.
    final tones = foretackTheme.extension<TextTones>()!;
    expect(styleOf(tester, '03').color, tones.low);
    expect(styleOf(tester, '46.9000, 18.0500').color, tones.low);
    expect(
      styleOf(tester, 'Szemes').color,
      foretackTheme.colorScheme.onSurface,
    );
  });
}
