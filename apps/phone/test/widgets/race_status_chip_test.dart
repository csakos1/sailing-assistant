import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:phone/widgets/race_status_chip.dart';

void main() {
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

  ColorScheme schemeOf(WidgetTester tester) =>
      Theme.of(tester.element(find.byType(RaceStatusChip))).colorScheme;

  group('RaceStatusChip', () {
    testWidgets('notStarted has no custom colours', (tester) async {
      await pumpChip(tester, RaceStatus.notStarted);
      expect(find.text('Nem indult'), findsOneWidget);
      expect(chipOf(tester).backgroundColor, isNull);
      expect(labelColourOf(tester, 'Nem indult'), isNull);
    });

    testWidgets('active uses the primary-container background', (
      tester,
    ) async {
      await pumpChip(tester, RaceStatus.active);
      final scheme = schemeOf(tester);
      expect(find.text('Folyamatban'), findsOneWidget);
      expect(chipOf(tester).backgroundColor, scheme.primaryContainer);
      expect(
        labelColourOf(tester, 'Folyamatban'),
        scheme.onPrimaryContainer,
      );
    });

    testWidgets('finished uses a muted background', (tester) async {
      await pumpChip(tester, RaceStatus.finished);
      final scheme = schemeOf(tester);
      expect(find.text('Befejezve'), findsOneWidget);
      final background = chipOf(tester).backgroundColor;
      expect(background, isNotNull);
      expect(background, isNot(scheme.primaryContainer));
      expect(labelColourOf(tester, 'Befejezve'), isNotNull);
    });
  });
}
