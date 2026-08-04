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

  // Ugyanaz a boja, megkerulesi idovel. A `Mark` ctora nem lehet const, mert
  // a `DateTime` nem konstans kifejezes.
  Mark roundedAt(DateTime at) => Mark(
    sequence: 3,
    name: 'Szemes',
    position: const Coordinate(latitude: 46.9, longitude: 18.05),
    roundedAt: at,
  );

  final rounded = roundedAt(DateTime(2026, 7, 20, 15, 42, 8));

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

  Finder textsInRow() => find.descendant(
    of: find.byType(DetailMarkRow),
    matching: find.byType(Text),
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

  testWidgets('renders the rounding time at the right edge', (tester) async {
    // ARRANGE & ACT
    await pumpRow(tester, rounded);

    // ASSERT - ADR 0044 Addendum 3: az ido jobb ele a sor 20 dp-s jobb
    // paddingjenel all, vagyis szemben a sorszam bal elevel.
    expect(find.text('15:42:08'), findsOneWidget);
    final rowRight = tester.getBottomRight(find.byType(DetailMarkRow)).dx;
    final timeRight = tester.getBottomRight(find.text('15:42:08')).dx;
    expect(timeRight, rowRight - 20);
  });

  testWidgets('leaves the slot empty when the mark was never rounded', (
    tester,
  ) async {
    // ARRANGE & ACT
    await pumpRow(tester, single);

    // ASSERT - sorszam + nev + koordinata; negyedik szoveg nincs, tehat
    // sem gondolatjel, sem placeholder nem kerul a helyere.
    expect(textsInRow(), findsNWidgets(3));

    // ACT
    await pumpRow(tester, rounded);

    // ASSERT
    expect(textsInRow(), findsNWidgets(4));
  });

  testWidgets('keeps the name left edge fixed with and without a time', (
    tester,
  ) async {
    // ARRANGE & ACT
    await pumpRow(tester, single);
    final withoutTime = tester.getTopLeft(find.text('Szemes')).dx;
    await pumpRow(tester, rounded);
    final withTime = tester.getTopLeft(find.text('Szemes')).dx;

    // ASSERT - ez az indoka annak, hogy az ido a jobb szelre kerult: a
    // nev-oszlop Expanded, tehat ido nelkul csak szelesebb lesz.
    expect(withTime, withoutTime);
  });

  testWidgets('renders the same wall clock for both instant flags', (
    tester,
  ) async {
    // ARRANGE - ugyanaz a pillanat ket zaszloval: a DB lokalis peldanyt ad
    // vissza, az elo motor UTC-jeloltet. A fixtura nem irhat be fix
    // eltolast, mert a CI UTC-ben fut, a fejlesztoi gep nem.
    final localFlagged = DateTime(2026, 7, 20, 15, 42, 8);
    final utcFlagged = localFlagged.toUtc();

    // ACT & ASSERT
    await pumpRow(tester, roundedAt(localFlagged));
    expect(find.text('15:42:08'), findsOneWidget);

    await pumpRow(tester, roundedAt(utcFlagged));
    expect(find.text('15:42:08'), findsOneWidget);
  });

  testWidgets('keeps the rounding time above the muted tone', (tester) async {
    // ARRANGE & ACT
    await pumpRow(tester, rounded);

    // ASSERT - harom tonus-szint all a soron; az ido a kozepso, mert a
    // soron a masodik legfontosabb adat.
    final tones = foretackTheme.extension<TextTones>()!;
    final timeStyle = styleOf(tester, '15:42:08');
    expect(timeStyle.color, foretackTheme.colorScheme.onSurfaceVariant);
    expect(timeStyle.color, isNot(tones.low));
    expect(timeStyle.fontSize, numeralMicroStyle.fontSize);
  });
}
