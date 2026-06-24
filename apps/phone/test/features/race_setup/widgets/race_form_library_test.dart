import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/features/race_setup/widgets/race_form.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:phone/providers/mark_library_repository_provider.dart';

void main() {
  testWidgets('a korábbi-bóják választás előtölt egy új sort', (tester) async {
    // ARRANGE — egy mentett bója a könyvtárban (a repo fake-jén át).
    final saved = SavedMark(
      name: 'VK',
      position: const Coordinate(latitude: 46.946554, longitude: 18.012115),
      sourceRaceName: 'Kedd esti',
      savedAt: DateTime.utc(2026, 6),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          markLibraryRepositoryProvider.overrideWithValue(
            _FakeMarkLibraryRepository([saved]),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('hu'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: RaceForm(onSubmit: (_, _) {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // create-mód: név + 1 üres bója-sor = 4 mező.
    expect(find.byType(TextFormField), findsNWidgets(4));

    // ACT — a picker megnyitása, majd a bója kiválasztása.
    await tester.tap(find.byIcon(Icons.history));
    await tester.pumpAndSettle();
    await tester.tap(find.text('VK'));
    await tester.pumpAndSettle();

    // ASSERT — új, előtöltött sor (név + 2 sor = 7 mező), a választott névvel
    // és tizedes-fok koordinátával.
    expect(find.byType(TextFormField), findsNWidgets(7));
    expect(find.text('VK'), findsOneWidget);
    expect(find.text('46.946554'), findsOneWidget);
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
