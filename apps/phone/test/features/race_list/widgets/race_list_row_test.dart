import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/app/localization_delegates.dart';
import 'package:phone/features/race_list/widgets/race_list_row.dart';
import 'package:phone/l10n/app_localizations.dart';

void main() {
  const mark = Mark(
    sequence: 1,
    name: 'Z1',
    position: Coordinate(latitude: 46.9, longitude: 18.05),
  );
  final clock = DateTime.utc(2025, 6, 1, 12);
  final scheme = foretackTheme.colorScheme;
  // A foretackTheme regisztralja a TextTones-t, tehat sosem null.
  final tones = foretackTheme.extension<TextTones>()!;

  Race notStartedRace() =>
      Race.create(id: 'r1', name: 'Alfa', marks: const [mark]);

  Future<void> pumpRow(
    WidgetTester tester,
    Race race, {
    String meta = '3 bója',
    bool isHighlighted = false,
    VoidCallback? onTap,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: foretackTheme,
        locale: const Locale('hu'),
        localizationsDelegates: phoneLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: RaceListRow(
            race: race,
            meta: meta,
            isHighlighted: isHighlighted,
            onTap: onTap,
          ),
        ),
      ),
    );
  }

  Finder coloredBoxWith(Color color) => find.byWidgetPredicate(
    (widget) => widget is ColoredBox && widget.color == color,
  );

  Color? colorOf(WidgetTester tester, String text) =>
      tester.widget<Text>(find.text(text)).style?.color;

  testWidgets('starts the name after the rail and the padding, unnumbered', (
    tester,
  ) async {
    // ARRANGE & ACT
    await pumpRow(tester, notStartedRace());

    // ASSERT - nincs sorszam-oszlop: 2 dp sin + 18 dp padding.
    expect(find.text('01'), findsNothing);
    expect(tester.getTopLeft(find.text('Alfa')).dx, 20);
  });

  testWidgets('shows the meta line under the name', (tester) async {
    // ARRANGE & ACT
    await pumpRow(tester, notStartedRace(), meta: 'MA · 09:00 · 1 bója');

    // ASSERT
    final nameBottom = tester.getBottomLeft(find.text('Alfa')).dy;
    final metaTop = tester.getTopLeft(find.text('MA · 09:00 · 1 bója')).dy;
    expect(metaTop - nameBottom, 5);
  });

  testWidgets('puts the status label at the right end', (tester) async {
    // ARRANGE & ACT
    await pumpRow(tester, notStartedRace());

    // ASSERT - a cimke jobb ele a 20 dp-s jobb padding elott all.
    final rowRight = tester.getTopRight(find.byType(RaceListRow)).dx;
    final badgeRight = tester.getTopRight(find.byType(StatusBadge)).dx;
    expect(badgeRight, rowRight - 20);
    expect(
      tester.getTopLeft(find.byType(StatusBadge)).dx,
      greaterThan(tester.getTopRight(find.text('Alfa')).dx),
    );
  });

  testWidgets('highlights a row with the rail, background and meta tone', (
    tester,
  ) async {
    // ARRANGE & ACT
    await pumpRow(tester, notStartedRace(), isHighlighted: true);

    // ASSERT
    expect(coloredBoxWith(scheme.primary), findsOneWidget);
    expect(colorOf(tester, '3 bója'), scheme.onSecondaryContainer);
    final material = tester.widget<Material>(
      find
          .descendant(
            of: find.byType(RaceListRow),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(material.color, scheme.surfaceContainer);
  });

  testWidgets('leaves a plain row unaccented but keeps the rail space', (
    tester,
  ) async {
    // ARRANGE & ACT
    await pumpRow(tester, notStartedRace());

    // ASSERT
    expect(coloredBoxWith(scheme.primary), findsNothing);
    expect(colorOf(tester, '3 bója'), tones.low);
    expect(tester.getTopLeft(find.text('Alfa')).dx, 20);
  });

  testWidgets('shows the running state on the label', (tester) async {
    // ARRANGE & ACT
    await pumpRow(
      tester,
      notStartedRace().start(at: clock),
      isHighlighted: true,
    );

    // ASSERT
    expect(find.text('FOLYAMATBAN'), findsOneWidget);
  });

  testWidgets('does not dim the name of a race that has not started', (
    tester,
  ) async {
    // ARRANGE & ACT
    await pumpRow(tester, notStartedRace());

    // ASSERT
    expect(colorOf(tester, 'Alfa'), scheme.onSurface);
  });

  testWidgets('reports a tap on the whole row', (tester) async {
    // ARRANGE
    var taps = 0;
    await pumpRow(tester, notStartedRace(), onTap: () => taps++);

    // ACT
    await tester.tap(find.byType(RaceListRow));
    await tester.pump();

    // ASSERT
    expect(taps, 1);
  });

  testWidgets('cuts a long meta line instead of wrapping it', (tester) async {
    // ARRANGE & ACT
    await pumpRow(tester, notStartedRace(), meta: 'NOV. 3. · 10:30 · ' * 6);

    // ASSERT
    final meta = tester.widget<Text>(find.textContaining('NOV. 3.'));
    expect(meta.maxLines, 1);
    expect(tester.takeException(), isNull);
  });
}
