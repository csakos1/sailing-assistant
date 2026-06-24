import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/features/race_setup/widgets/saved_mark_picker.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:phone/providers/mark_library_provider.dart';

void main() {
  Future<void> pumpPicker(
    WidgetTester tester,
    List<SavedMark> marks,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          markLibraryProvider.overrideWith((ref) => Stream.value(marks)),
        ],
        child: const MaterialApp(
          locale: Locale('hu'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: SavedMarkPicker()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  AppLocalizations l10nOf(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(SavedMarkPicker)))!;

  testWidgets('üres könyvtárnál az üres-állapot szöveg jelenik meg', (
    tester,
  ) async {
    // ARRANGE & ACT
    await pumpPicker(tester, const []);

    // ASSERT
    expect(find.text(l10nOf(tester).setupPickFromLibraryEmpty), findsOneWidget);
  });

  testWidgets('soronként a bója nevét és a forrás-versenyt mutatja', (
    tester,
  ) async {
    // ARRANGE
    final marks = [
      SavedMark(
        name: 'VK',
        position: const Coordinate(latitude: 46.946554, longitude: 18.012115),
        sourceRaceName: 'Kedd esti',
        savedAt: DateTime.utc(2026, 6, 2),
      ),
      SavedMark(
        name: 'BS',
        position: const Coordinate(latitude: 46.931763, longitude: 18.045607),
        sourceRaceName: 'Szerda',
        savedAt: DateTime.utc(2026, 6),
      ),
    ];

    // ACT
    await pumpPicker(tester, marks);

    // ASSERT — név + forrás-verseny minden sorban, koordináta nélkül.
    expect(find.text('VK'), findsOneWidget);
    expect(find.text('Kedd esti'), findsOneWidget);
    expect(find.text('BS'), findsOneWidget);
    expect(find.text('Szerda'), findsOneWidget);
    expect(find.text('46.946554'), findsNothing);
  });
}
