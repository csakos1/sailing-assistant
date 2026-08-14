import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/app/theme.dart';
import 'package:phone/features/race_setup/widgets/saved_mark_picker.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:phone/providers/mark_library_provider.dart';

void main() {
  // A picker a témából olvassa a TextTones-t, ezért a foretackTheme-et
  // kötelező megadni — enélkül a kiterjesztés-olvasás azonnal dobna.
  Future<void> pumpPicker(
    WidgetTester tester,
    List<SavedMark> marks,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          markLibraryProvider.overrideWith((ref) => Stream.value(marks)),
        ],
        child: MaterialApp(
          theme: foretackTheme,
          locale: const Locale('hu'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: SavedMarkPicker()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  AppLocalizations l10nOf(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(SavedMarkPicker)))!;

  Future<void> search(WidgetTester tester, String query) async {
    await tester.enterText(find.byType(TextField), query);
    await tester.pumpAndSettle();
  }

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

  testWidgets('üres könyvtárnál az üres-állapot szöveg jelenik meg', (
    tester,
  ) async {
    // ARRANGE & ACT
    await pumpPicker(tester, const []);

    // ASSERT
    expect(find.text(l10nOf(tester).setupPickFromLibraryEmpty), findsOneWidget);
  });

  // Az ADR 0044 D51 óta a koordináta IS látszik: ez az ADR 0032 L8
  // „koordináta nélkül" kikötésének visszavonása, és a korábbi teszt
  // épp az ellenkezőjét rögzítette.
  testWidgets('soronként a nevet, a koordinátát és a forrás-versenyt mutatja', (
    tester,
  ) async {
    // ARRANGE & ACT
    await pumpPicker(tester, marks);

    // ASSERT
    expect(find.text('VK'), findsOneWidget);
    expect(find.text('46.9466 · 18.0121'), findsOneWidget);
    expect(find.text('BS'), findsOneWidget);
    expect(find.text('46.9318 · 18.0456'), findsOneWidget);
  });

  testWidgets('a forrás-verseny verzállal áll a badge-ben', (tester) async {
    // ARRANGE & ACT
    await pumpPicker(tester, marks);

    // ASSERT — a nagybetűsítés a megjelenítésé, az adat érintetlen.
    expect(find.text('KEDD ESTI'), findsOneWidget);
    expect(find.text('Kedd esti'), findsNothing);
  });

  testWidgets('a fejléc a könyvtár darabszámát mutatja', (tester) async {
    // ARRANGE & ACT
    await pumpPicker(tester, marks);

    // ASSERT
    expect(find.text(l10nOf(tester).setupPickFromLibraryTitle), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('üres könyvtárnál nincs darabszám és nincs kereső', (
    tester,
  ) async {
    // ARRANGE & ACT
    await pumpPicker(tester, const []);

    // ASSERT — a nulla darabszám kiírása zajt adna az üres-állapot mellé,
    // és üres könyvtárban nincs mit szűrni.
    expect(find.text('0'), findsNothing);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('a keresés névre szűri a listát', (tester) async {
    // ARRANGE
    await pumpPicker(tester, marks);

    // ACT
    await search(tester, 'vk');

    // ASSERT — kis-nagybetűtől függetlenül csak az egyező sor marad.
    expect(find.text('VK'), findsOneWidget);
    expect(find.text('BS'), findsNothing);
  });

  testWidgets('a darabszám a szűrt listát követi', (tester) async {
    // ARRANGE
    await pumpPicker(tester, marks);
    expect(find.text('2'), findsOneWidget);

    // ACT
    await search(tester, 'vk');

    // ASSERT
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsNothing);
  });

  // Szűrés után a "Még nincs mentett bója." hazudna: van mentett bója,
  // csak nem erre a névre.
  testWidgets('eredménytelen szűrésnél külön üres-állapot jön', (
    tester,
  ) async {
    // ARRANGE
    await pumpPicker(tester, marks);

    // ACT
    await search(tester, 'zzz');

    // ASSERT
    final l10n = l10nOf(tester);
    expect(find.text(l10n.setupPickFromLibraryNoMatch), findsOneWidget);
    expect(find.text(l10n.setupPickFromLibraryEmpty), findsNothing);
  });

  testWidgets('a kereső megmarad, ha a szűrés nullára fut ki', (tester) async {
    // ARRANGE
    await pumpPicker(tester, marks);

    // ACT
    await search(tester, 'zzz');

    // ASSERT — enélkül nem lenne mivel visszalépni a teljes listára.
    expect(find.byType(TextField), findsOneWidget);
  });

  // Regresszio-or: szures utan a lap NEM zsugorodik a talalatok
  // meretere, kulonben a billentyuzet ala kerulne.
  testWidgets('a lap magassága nem függ a találatok számától', (
    tester,
  ) async {
    // ARRANGE
    await pumpPicker(tester, marks);
    final full = tester.getSize(find.byType(SavedMarkPicker)).height;

    // ACT
    await search(tester, 'vk');

    // ASSERT
    final filtered = tester.getSize(find.byType(SavedMarkPicker));
    expect(filtered.height, full);
  });
}
