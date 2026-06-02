import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/app/theme.dart';
import 'package:phone/app/warning_colors.dart';
import 'package:phone/features/live_race/widgets/warning_banner.dart';
import 'package:phone/l10n/app_localizations.dart';

void main() {
  Future<void> pump(WidgetTester tester, List<Warning> warnings) =>
      tester.pumpWidget(
        MaterialApp(
          theme: foretackTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: WarningBanner(warnings: warnings)),
        ),
      );

  Color stripBackground(WidgetTester tester, String message) {
    final container = tester.widget<Container>(
      find
          .ancestor(of: find.text(message), matching: find.byType(Container))
          .first,
    );
    return (container.decoration! as BoxDecoration).color!;
  }

  final warningColors = foretackTheme.extension<WarningColors>()!;

  group('WarningBanner', () {
    testWidgets('üres lista → nem renderel semmit', (tester) async {
      await pump(tester, const []);
      expect(find.byType(Icon), findsNothing);
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('critical warning → üzenet, error ikon, piros háttér', (
      tester,
    ) async {
      await pump(tester, const [GpsSignalLost()]);
      expect(find.text('Nincs GPS-jel'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);
      expect(stripBackground(tester, 'Nincs GPS-jel'), warningColors.critical);
    });

    testWidgets('info warning → diszkrét háttér + info ikon', (tester) async {
      await pump(tester, const [WindShiftTrendInsufficient()]);
      expect(find.text('Kevés széladat a trendhez'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
      expect(
        stripBackground(tester, 'Kevés széladat a trendhez'),
        warningColors.info,
      );
    });

    testWidgets('több warning → mind, a megadott sorrendben', (tester) async {
      await pump(tester, const [
        GpsSignalLost(),
        GpsTimeUnsynced(),
        WindShiftTrendInsufficient(),
      ]);

      final messages = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .toList();
      expect(messages, [
        'Nincs GPS-jel',
        'GPS-idő nincs szinkronban',
        'Kevés széladat a trendhez',
      ]);
    });
  });
}
