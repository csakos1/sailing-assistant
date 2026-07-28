import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/app/marine_colors.dart';
import 'package:phone/app/text_tones.dart';
import 'package:phone/app/theme.dart';
import 'package:phone/app/true_time.dart';
import 'package:phone/app/warning_colors.dart';
import 'package:phone/features/live_race/widgets/live_status_bar.dart';
import 'package:phone/l10n/app_localizations.dart';

// A temabol olvassuk az elvart szineket, hogy a teszt a LEKEPEZEST rogzitse
// (allapot -> token), ne a hexeket.
final WarningColors _warningColors = foretackTheme.extension<WarningColors>()!;
final TextTones _tones = foretackTheme.extension<TextTones>()!;

Future<void> _pump(
  WidgetTester tester, {
  required ConnectionStatus status,
  bool isStale = false,
  TrueTimeSource source = TrueTimeSource.gnss,
}) => tester.pumpWidget(
  MaterialApp(
    theme: foretackTheme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: LiveStatusBar(
        connectionStatus: status,
        markName: '1. boja',
        trueTime: TrueTimeReading(
          utc: DateTime(2026, 5, 29, 14, 32, 7),
          source: source,
        ),
        isStale: isStale,
      ),
    ),
  ),
);

Color _dotColor(WidgetTester tester) {
  // A statuszsor mindig rajzol pontot, es a szinet mindig megadja.
  return tester.widget<Icon>(find.byIcon(Icons.circle)).color!;
}

void main() {
  group('LiveStatusBar connection dot', () {
    testWidgets('connected uses the accent, never the starboard green', (
      tester,
    ) async {
      await _pump(tester, status: const Connected());

      expect(find.text('Csatlakozva'), findsOneWidget);
      expect(_dotColor(tester), foretackTheme.colorScheme.primary);
      expect(_dotColor(tester), isNot(starboardColor));
    });

    testWidgets('connecting uses the warning token', (tester) async {
      await _pump(tester, status: const Connecting());

      expect(_dotColor(tester), _warningColors.warning);
    });

    testWidgets('disconnected uses the tertiary text tone', (tester) async {
      await _pump(tester, status: const Disconnected());

      expect(_dotColor(tester), _tones.low);
    });

    testWidgets('a connection error uses the critical token and shows the '
        'message', (tester) async {
      await _pump(tester, status: const ConnectionError('Szakadt'));

      expect(find.text('Hiba: Szakadt'), findsOneWidget);
      expect(_dotColor(tester), _warningColors.critical);
    });
  });

  group('LiveStatusBar stale chip', () {
    testWidgets('is absent while the data is fresh', (tester) async {
      await _pump(tester, status: const Connected());

      expect(find.byIcon(Icons.schedule), findsNothing);
    });

    testWidgets('carries the warning token when the data is old', (
      tester,
    ) async {
      await _pump(tester, status: const Connected(), isStale: true);

      final icon = tester.widget<Icon>(find.byIcon(Icons.schedule));
      expect(icon.color, _warningColors.warning);
    });
  });

  group('LiveStatusBar clock', () {
    testWidgets('renders the instrument time as is when synced', (
      tester,
    ) async {
      await _pump(tester, status: const Connected());

      expect(find.text('14:32:07'), findsOneWidget);
    });

    testWidgets('marks an unsynced clock with a tilde', (tester) async {
      await _pump(
        tester,
        status: const Connected(),
        source: TrueTimeSource.wallClockUnsynced,
      );

      expect(find.text('~14:32:07'), findsOneWidget);
    });
  });
}
