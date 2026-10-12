import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/library/persist_race_marks_to_library.dart';

void main() {
  final savedAt = DateTime.utc(2026, 10, 12, 8);
  const mark = Mark(
    sequence: 1,
    name: 'Z1',
    position: Coordinate(latitude: 46.9, longitude: 18.05),
  );
  const startPoint = StartPoint(
    name: 'Rajt',
    position: Coordinate(latitude: 46.95, longitude: 17.9),
  );

  test('saves the start point first, then the marks', () async {
    // ARRANGE
    final repository = _RecordingRepository();
    final race = Race.create(
      id: 'r1',
      name: 'Kedd esti',
      marks: const [mark],
      startPoint: startPoint,
    );

    // ACT
    await persistRaceMarksToLibrary(
      repository: repository,
      race: race,
      savedAt: savedAt,
    );

    // ASSERT - egy idobelyeg, a verseny neve mint forras.
    expect(repository.saved, [
      SavedMark(
        name: 'Rajt',
        position: startPoint.position,
        sourceRaceName: 'Kedd esti',
        savedAt: savedAt,
      ),
      SavedMark(
        name: 'Z1',
        position: mark.position,
        sourceRaceName: 'Kedd esti',
        savedAt: savedAt,
      ),
    ]);
  });

  test('saves the start point of a markless race', () async {
    // ARRANGE
    final repository = _RecordingRepository();
    final race = Race.create(
      id: 'r1',
      name: 'Tura',
      marks: const [],
      startPoint: startPoint,
    );

    // ACT
    await persistRaceMarksToLibrary(
      repository: repository,
      race: race,
      savedAt: savedAt,
    );

    // ASSERT
    expect(repository.saved.map((saved) => saved.name), ['Rajt']);
  });

  test('saves only the marks without a start point', () async {
    // ARRANGE
    final repository = _RecordingRepository();
    final race = Race.create(id: 'r1', name: 'V', marks: const [mark]);

    // ACT
    await persistRaceMarksToLibrary(
      repository: repository,
      race: race,
      savedAt: savedAt,
    );

    // ASSERT
    expect(repository.saved.map((saved) => saved.name), ['Z1']);
  });

  test('swallows a library failure (best effort)', () async {
    // ARRANGE
    final race = Race.create(id: 'r1', name: 'V', marks: const [mark]);

    // ACT & ASSERT - a hiba nem jut a hivoig.
    await expectLater(
      persistRaceMarksToLibrary(
        repository: _ThrowingRepository(),
        race: race,
        savedAt: savedAt,
      ),
      completes,
    );
  });
}

class _RecordingRepository implements MarkLibraryRepository {
  final saved = <SavedMark>[];

  @override
  Future<void> saveAll(Iterable<SavedMark> marks) async {
    saved.addAll(marks);
  }

  @override
  Stream<List<SavedMark>> watchAll() => const Stream<List<SavedMark>>.empty();
}

class _ThrowingRepository implements MarkLibraryRepository {
  @override
  Future<void> saveAll(Iterable<SavedMark> marks) async {
    throw StateError('konyvtar-irasi hiba');
  }

  @override
  Stream<List<SavedMark>> watchAll() => const Stream<List<SavedMark>>.empty();
}
