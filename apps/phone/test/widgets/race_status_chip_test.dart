import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/app/marine_colors.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:phone/widgets/race_status_chip.dart';

void main() {
  // A chipet HU locale-lal pumpoljuk, hogy a feliratok determinisztikusak
  // legyenek (a teszt a magyar ARB-stringekre matchel).
  Future<void> pumpChip(WidgetTester tester, RaceStatus status) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('hu'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: RaceStatusChip(status: status)),
      ),
    );
  }

  Chip chipOf(WidgetTester tester) => tester.widget<Chip>(find.byType(Chip));

  Color? labelColourOf(WidgetTester tester, String text) =>
      tester.widget<Text>(find.text(text)).style?.color;

  group('RaceStatusChip', () {
    testWidgets('notStarted has no custom colours', (tester) async {
      await pumpChip(tester, RaceStatus.notStarted);

      expect(find.text('Nem indult'), findsOneWidget);
      expect(chipOf(tester).backgroundColor, isNull);
      expect(labelColourOf(tester, 'Nem indult'), isNull);
    });

    testWidgets('active uses the teal background', (tester) async {
      await pumpChip(tester, RaceStatus.active);

      expect(find.text('Folyamatban'), findsOneWidget);
      expect(chipOf(tester).backgroundColor, inProgressColor);
      expect(labelColourOf(tester, 'Folyamatban'), Colors.white);
    });

    testWidgets('finished uses a muted background', (tester) async {
      await pumpChip(tester, RaceStatus.finished);

      expect(find.text('Befejezve'), findsOneWidget);
      final background = chipOf(tester).backgroundColor;
      // finished: téma-surface (nem null és nem a teal token).
      expect(background, isNotNull);
      expect(background, isNot(inProgressColor));
      expect(labelColourOf(tester, 'Befejezve'), isNotNull);
    });
  });
}
