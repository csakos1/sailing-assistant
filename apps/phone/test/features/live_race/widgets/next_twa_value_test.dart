import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/features/live_race/widgets/confidence_dots.dart';
import 'package:phone/features/live_race/widgets/next_twa_value.dart';
import 'package:phone/features/live_race/widgets/twa_value.dart';
import 'package:phone/l10n/app_localizations.dart';

void main() {
  group('NextTwaValue', () {
    // A widgetet lokalizációval pumpáljuk, hogy a „tartott" felirat éljen.
    Future<void> pump(
      WidgetTester tester, {
      required Angle? twa,
      required TwdQuality twdQuality,
      required WindShiftConfidence? confidence,
    }) {
      return tester.pumpWidget(
        MaterialApp(
          locale: const Locale('hu'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: NextTwaValue(
              twa: twa,
              twdQuality: twdQuality,
              confidence: confidence,
            ),
          ),
        ),
      );
    }

    // A hero-t közvetlenül körülvevő Opacity (incidentális Opacity-k ellen).
    double heroOpacity(WidgetTester tester) {
      final opacity = tester.widget<Opacity>(
        find.ancestor(
          of: find.byType(TwaValue),
          matching: find.byType(Opacity),
        ),
      );
      return opacity.opacity;
    }

    testWidgets('held dims the hero and shows the held marker', (tester) async {
      // Act
      await pump(
        tester,
        twa: const Angle(degrees: 40),
        twdQuality: TwdQuality.held,
        confidence: WindShiftConfidence.medium,
      );
      await tester.pumpAndSettle();

      // Assert
      expect(heroOpacity(tester), 0.6);
      expect(find.text('tartott'), findsOneWidget);
    });

    testWidgets('live keeps full opacity and no held marker', (tester) async {
      // Act
      await pump(
        tester,
        twa: const Angle(degrees: 40),
        twdQuality: TwdQuality.live,
        confidence: WindShiftConfidence.high,
      );
      await tester.pumpAndSettle();

      // Assert
      expect(heroOpacity(tester), 1.0);
      expect(find.text('tartott'), findsNothing);
    });

    testWidgets('unavailable renders a null hero, no held marker', (
      tester,
    ) async {
      // Act — unavailable mellett a predikció jellemzően null
      await pump(
        tester,
        twa: null,
        twdQuality: TwdQuality.unavailable,
        confidence: null,
      );
      await tester.pumpAndSettle();

      // Assert
      expect(heroOpacity(tester), 1.0);
      expect(find.text('tartott'), findsNothing);
      expect(tester.widget<TwaValue>(find.byType(TwaValue)).twa, isNull);
    });

    testWidgets('confidence presence drives the dots', (tester) async {
      // Van predikció → pöttyök
      await pump(
        tester,
        twa: const Angle(degrees: 30),
        twdQuality: TwdQuality.live,
        confidence: WindShiftConfidence.low,
      );
      await tester.pumpAndSettle();
      expect(find.byType(ConfidenceDots), findsOneWidget);

      // Nincs predikció → nincs pötty
      await pump(
        tester,
        twa: null,
        twdQuality: TwdQuality.unavailable,
        confidence: null,
      );
      await tester.pumpAndSettle();
      expect(find.byType(ConfidenceDots), findsNothing);
    });
  });
}
