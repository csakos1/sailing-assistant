import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/app/theme.dart';
import 'package:phone/features/live_race/widgets/confidence_dots.dart';
import 'package:phone/features/live_race/widgets/predicted_twa_cell.dart';
import 'package:phone/features/live_race/widgets/twa_value.dart';
import 'package:phone/l10n/app_localizations.dart';

// A cella a szulo flexebol kapja a magassagat, ezert kotott dobozba tesszuk.
Future<void> _pump(
  WidgetTester tester, {
  required TwdQuality twdQuality,
  Angle? twa = const Angle(degrees: -47),
  WindShiftConfidence? confidence = WindShiftConfidence.medium,
  double? band,
}) => tester.pumpWidget(
  MaterialApp(
    theme: foretackTheme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SizedBox(
        height: 300,
        child: PredictedTwaCell(
          twa: twa,
          twdQuality: twdQuality,
          confidence: confidence,
          bandDegrees: band,
        ),
      ),
    ),
  ),
);

double _heroOpacity(WidgetTester tester) {
  final finder = find
      .ancestor(of: find.byType(TwaValue), matching: find.byType(Opacity))
      .first;
  return tester.widget<Opacity>(finder).opacity;
}

void main() {
  group('PredictedTwaCell', () {
    testWidgets('live TWD quality renders the hero at full opacity', (
      tester,
    ) async {
      await _pump(tester, twdQuality: TwdQuality.live);

      expect(find.text('47°'), findsOneWidget);
      expect(_heroOpacity(tester), 1.0);
      expect(find.text('TARTOTT'), findsNothing);
    });

    testWidgets('held TWD quality dims the hero and labels it', (
      tester,
    ) async {
      await _pump(tester, twdQuality: TwdQuality.held);

      expect(_heroOpacity(tester), 0.6);
      expect(find.text('TARTOTT'), findsOneWidget);
    });

    testWidgets('renders the forecast band under the hero', (tester) async {
      await _pump(tester, twdQuality: TwdQuality.live, band: 4.3);

      expect(find.text('±4°'), findsOneWidget);
    });

    testWidgets('renders the confidence dots', (tester) async {
      await _pump(tester, twdQuality: TwdQuality.live);

      expect(find.byType(ConfidenceDots), findsOneWidget);
    });

    testWidgets('without a prediction there are no dots and no band', (
      tester,
    ) async {
      await _pump(
        tester,
        twdQuality: TwdQuality.unavailable,
        twa: null,
        confidence: null,
      );

      expect(find.text('—'), findsOneWidget);
      expect(find.byType(ConfidenceDots), findsNothing);
      expect(find.textContaining('±'), findsNothing);
    });
  });
}
