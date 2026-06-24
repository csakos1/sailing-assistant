import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

const _position = Coordinate(latitude: 46.946554, longitude: 18.012115);

/// Teszt-helper: alapértelmezett mezőkkel ad egy [SavedMark]-ot, a
/// vizsgált különbséget named paraméterrel írjuk felül (a savedAt
/// default-ja null, így átadása sosem redundáns argumentum).
SavedMark _mark({
  String name = 'VK',
  String sourceRaceName = 'Kedd esti',
  DateTime? savedAt,
}) {
  return SavedMark(
    name: name,
    position: _position,
    sourceRaceName: sourceRaceName,
    savedAt: savedAt ?? DateTime.utc(2026, 6),
  );
}

void main() {
  late AppDatabase db;
  late MarkLibraryRepositoryImpl repository;

  setUp(() {
    // Friss in-memory DB → onCreate/createAll, beleértve a savedMarks
    // táblát és a unique indexet.
    db = AppDatabase(NativeDatabase.memory());
    repository = MarkLibraryRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('MarkLibraryRepositoryImpl', () {
    test('saveAll után a watchAll a mentett bóját adja vissza', () async {
      // ARRANGE & ACT
      await repository.saveAll([_mark()]);

      // ASSERT — az E7 körbe-oda konverzió is helyes.
      final marks = await repository.watchAll().first;
      expect(marks, hasLength(1));
      final saved = marks.single;
      expect(saved.name, equals('VK'));
      expect(saved.position.latitude, closeTo(46.946554, 1e-7));
      expect(saved.position.longitude, closeTo(18.012115, 1e-7));
      expect(saved.sourceRaceName, equals('Kedd esti'));
    });

    test('azonos négyes nem duplikál, a savedAt az elsőé marad', () async {
      // ARRANGE
      final first = DateTime.utc(2026, 6);
      final second = DateTime.utc(2026, 6, 2);

      // ACT — kétszer ugyanaz az identity-négyes (csak a savedAt más).
      await repository.saveAll([_mark(savedAt: first)]);
      await repository.saveAll([_mark(savedAt: second)]);

      // ASSERT — INSERT OR IGNORE: egy sor, az eredeti savedAt-tal (L3).
      // isAtSameMomentAs: a Drift int-epoch tárolás lokális DateTime-ot ad
      // vissza, a DateTime.== az isUtc-t is nézné.
      final marks = await repository.watchAll().first;
      expect(marks, hasLength(1));
      expect(marks.single.savedAt.isAtSameMomentAs(first), isTrue);
    });

    test('eltérő forrás-verseny -> külön sor (előfordulás-napló)', () async {
      // ARRANGE & ACT — azonos név+pozíció, más verseny → két előfordulás.
      await repository.saveAll([_mark(sourceRaceName: 'A verseny')]);
      await repository.saveAll([_mark(sourceRaceName: 'B verseny')]);

      // ASSERT
      final marks = await repository.watchAll().first;
      expect(marks, hasLength(2));
    });

    test('watchAll a savedAt szerint csökkenőben rendez', () async {
      // ARRANGE
      final older = DateTime.utc(2026, 6);
      final newer = DateTime.utc(2026, 6, 2);

      // ACT — két külön előfordulás, eltérő mentési idővel.
      await repository.saveAll([
        _mark(sourceRaceName: 'régi', savedAt: older),
        _mark(sourceRaceName: 'új', savedAt: newer),
      ]);

      // ASSERT — a frissebb elöl.
      final marks = await repository.watchAll().first;
      expect(
        marks.map((m) => m.sourceRaceName),
        equals(['új', 'régi']),
      );
    });
  });
}
