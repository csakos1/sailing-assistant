import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/app/localization_delegates.dart';
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
          localizationsDelegates: phoneLocalizationsDelegates,
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

  // Az ADR 0044 D51 ota a koordinata IS latszik (az ADR 0032 L8
  // visszavonasa); a 35c ota egy sorban, a nev mellett.
  testWidgets('soronként a nevet és a koordinátát mutatja', (tester) async {
    // ARRANGE & ACT
    await pumpPicker(tester, marks);

    // ASSERT
    expect(find.text('VK'), findsOneWidget);
    expect(find.text('46.9466 · 18.0121'), findsOneWidget);
    expect(find.text('BS'), findsOneWidget);
    expect(find.text('46.9318 · 18.0456'), findsOneWidget);
  });

  testWidgets('a bójákat forrás-verseny szerint csoportosítja', (
    tester,
  ) async {
    // ARRANGE & ACT
    await pumpPicker(tester, marks);

    // ASSERT - a csoport-fejlec a verseny neve, a megadott alakban (a
    // 35c nem verzaloz), es a legutobb mentett verseny all elol.
    final keddY = tester.getTopLeft(find.text('Kedd esti')).dy;
    final szerdaY = tester.getTopLeft(find.text('Szerda')).dy;
    expect(keddY, lessThan(tester.getTopLeft(find.text('VK')).dy));
    expect(tester.getTopLeft(find.text('VK')).dy, lessThan(szerdaY));
    expect(szerdaY, lessThan(tester.getTopLeft(find.text('BS')).dy));
  });

  testWidgets('a keresőmező a látható bóják számát mutatja', (tester) async {
    // ARRANGE & ACT
    await pumpPicker(tester, marks);

    // ASSERT
    expect(
      find.text(l10nOf(tester).setupPickFromLibraryCount(2)),
      findsOneWidget,
    );
  });

  testWidgets('a csoport utolsó sora alatt a vonal él-től él-ig fut', (
    tester,
  ) async {
    // ARRANGE - ket boja ugyanabbol a versenybol.
    await pumpPicker(tester, [
      marks.first,
      SavedMark(
        name: 'Z1',
        position: const Coordinate(latitude: 46.9, longitude: 17.9),
        sourceRaceName: 'Kedd esti',
        savedAt: DateTime.utc(2026, 6, 2),
      ),
    ]);

    // ACT - a sorok also vonalai (1 dp magas ColoredBox-ok a sorokban).
    double lineLeftUnder(String name) {
      final row = find.ancestor(
        of: find.text(name),
        matching: find.byType(InkWell),
      );
      final line = find.descendant(
        of: row,
        matching: find.byWidgetPredicate(
          (widget) => widget is Positioned && widget.height == 1,
        ),
      );
      return tester.getTopLeft(line).dx;
    }

    // ASSERT - a csoporton beluli vonal 20 dp-s betettel, a zaro a szelen.
    expect(lineLeftUnder('VK'), 20);
    expect(lineLeftUnder('Z1'), 0);
  });

  testWidgets('üres könyvtárnál nincs darabszám és nincs kereső', (
    tester,
  ) async {
    // ARRANGE & ACT
    await pumpPicker(tester, const []);

    // ASSERT - ures konyvtarban nincs mit szurni, igy a mezo es vele a
    // darabszam sem jelenik meg.
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
    final l10n = l10nOf(tester);

    // ACT
    await search(tester, 'vk');

    // ASSERT
    expect(find.text(l10n.setupPickFromLibraryCount(1)), findsOneWidget);
    expect(find.text(l10n.setupPickFromLibraryCount(2)), findsNothing);
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
