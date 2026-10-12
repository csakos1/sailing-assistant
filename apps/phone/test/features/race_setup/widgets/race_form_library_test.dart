import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/app/localization_delegates.dart';
import 'package:phone/features/race_setup/widgets/form_action_bar.dart';
import 'package:phone/features/race_setup/widgets/race_form.dart';
import 'package:phone/features/race_setup/widgets/start_point_empty_card.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:phone/providers/mark_library_repository_provider.dart';

void main() {
  final saved = SavedMark(
    name: 'VK',
    position: const Coordinate(latitude: 46.946554, longitude: 18.012115),
    sourceRaceName: 'Kedd esti',
    savedAt: DateTime.utc(2026, 6),
  );

  // Egy mentett boja a konyvtarban (a repo fake-jen at).
  Future<void> pumpForm(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          markLibraryRepositoryProvider.overrideWithValue(
            _FakeMarkLibraryRepository([saved]),
          ),
        ],
        child: MaterialApp(
          theme: foretackTheme,
          locale: const Locale('hu'),
          localizationsDelegates: phoneLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: RaceForm(onSubmit: (_) {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a korábbi-bóják választás előtölt egy új sort', (tester) async {
    // ARRANGE - create-mod: nev + 1 ures boja-sor = 4 mezo.
    await pumpForm(tester);
    expect(find.byType(TextFormField), findsNWidgets(4));

    // ACT - a sav "Korabbi bojak" gombja, majd a boja kivalasztasa.
    await tester.tap(
      find.descendant(
        of: find.byType(FormActionBar),
        matching: find.byIcon(Icons.history),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('VK'));
    await tester.pumpAndSettle();

    // ASSERT — új, előtöltött sor (név + 2 sor = 7 mező), a választott névvel
    // és tizedes-fok koordinátával.
    expect(find.byType(TextFormField), findsNWidgets(7));
    expect(find.text('VK'), findsOneWidget);
    expect(find.text('46.946554'), findsOneWidget);
  });

  testWidgets('a rajthely a könyvtárból választható', (tester) async {
    // ARRANGE
    await pumpForm(tester);

    // ACT - az ures rajthely-kartya konyvtar-utja.
    await tester.tap(
      find.descendant(
        of: find.byType(StartPointEmptyCard),
        matching: find.byIcon(Icons.history),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('VK'));
    await tester.pumpAndSettle();

    // ASSERT - a rajthely kitoltve (nev + 3 + 3 mezo), a boja-sor ures
    // maradt, es az ures kartya eltunt.
    expect(find.byType(StartPointEmptyCard), findsNothing);
    expect(find.byType(TextFormField), findsNWidgets(7));
    final fields = find.byType(TextFormField);
    expect(
      tester.widget<TextFormField>(fields.at(1)).controller?.text,
      'VK',
    );
    expect(
      tester.widget<TextFormField>(fields.at(4)).controller?.text,
      isEmpty,
    );
  });
}

class _FakeMarkLibraryRepository implements MarkLibraryRepository {
  _FakeMarkLibraryRepository(this._marks);

  final List<SavedMark> _marks;

  @override
  Future<void> saveAll(Iterable<SavedMark> marks) async {}

  @override
  Stream<List<SavedMark>> watchAll() => Stream.value(_marks);
}
