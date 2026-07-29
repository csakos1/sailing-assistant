import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/app/text_tones.dart';
import 'package:phone/app/theme.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:phone/widgets/status_badge.dart';

void main() {
  final scheme = foretackTheme.colorScheme;
  // A foretackTheme regisztralja a TextTones-t, tehat sosem null.
  final tones = foretackTheme.extension<TextTones>()!;

  Future<void> pumpBadge(WidgetTester tester, RaceStatus status) {
    return tester.pumpWidget(
      MaterialApp(
        theme: foretackTheme,
        locale: const Locale('hu'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: StatusBadge(status: status)),
      ),
    );
  }

  BoxDecoration markerDecoration(WidgetTester tester) {
    final box = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byType(StatusBadge),
        matching: find.byType(DecoratedBox),
      ),
    );
    return box.decoration as BoxDecoration;
  }

  Color? labelColorOf(WidgetTester tester, String label) =>
      tester.widget<Text>(find.text(label)).style?.color;

  testWidgets('draws the not started marker hollow', (tester) async {
    // ARRANGE & ACT
    await pumpBadge(tester, RaceStatus.notStarted);

    // ASSERT
    final decoration = markerDecoration(tester);
    expect(find.text('NEM INDULT'), findsOneWidget);
    expect(decoration.color, isNull);
    expect(decoration.border, isNotNull);
    expect(labelColorOf(tester, 'NEM INDULT'), tones.low);
  });

  testWidgets('fills the active marker with the primary tone', (tester) async {
    // ARRANGE & ACT
    await pumpBadge(tester, RaceStatus.active);

    // ASSERT
    final decoration = markerDecoration(tester);
    expect(find.text('FOLYAMATBAN'), findsOneWidget);
    expect(decoration.color, scheme.primary);
    expect(decoration.border, isNull);
    expect(labelColorOf(tester, 'FOLYAMATBAN'), scheme.primary);
  });

  testWidgets('mutes the finished marker below its own label', (tester) async {
    // ARRANGE & ACT
    await pumpBadge(tester, RaceStatus.finished);

    // ASSERT - ez az az eset, amit a korabbi bool felulet nem tudott
    // kifejezni: a jelolo tompitott, a felirat viszont vilagosabb nala.
    final decoration = markerDecoration(tester);
    expect(find.text('BEFEJEZETT'), findsOneWidget);
    expect(decoration.color, tones.low);
    expect(labelColorOf(tester, 'BEFEJEZETT'), scheme.onSurfaceVariant);
    expect(labelColorOf(tester, 'BEFEJEZETT'), isNot(decoration.color));
  });

  testWidgets('keeps the marker at 7x7 in every state', (tester) async {
    for (final status in RaceStatus.values) {
      // ARRANGE & ACT
      await pumpBadge(tester, status);

      // ASSERT - a keret a dobozon BELUL rajzolodik, tehat a kulso meret
      // allapottol fuggetlen.
      final size = tester.getSize(
        find.descendant(
          of: find.byType(StatusBadge),
          matching: find.byType(DecoratedBox),
        ),
      );
      expect(size, const Size(7, 7), reason: '$status');
    }
  });
}
