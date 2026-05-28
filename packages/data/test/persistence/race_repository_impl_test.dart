import 'package:data/src/persistence/app_database.dart';
import 'package:data/src/persistence/repositories/race_repository_impl.dart';
import 'package:domain/domain.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late RaceRepositoryImpl repository;

  // Rögzített óra a createdAt determinizmusához. Lokális DateTime: a Drift
  // legacy datetime-módban Unix-másodpercként tárol és lokálisként olvas
  // vissza (isUtc=false). UTC fixture-ral az Equatable == elhasalna az
  // isUtc-flagen, hiába azonos a pillanat.
  final fixedNow = DateTime(2025, 6, 1, 10);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = RaceRepositoryImpl(db, now: () => fixedNow);
  });

  tearDown(() async {
    await db.close();
  });

  const markA = Mark(
    sequence: 1,
    name: 'Z1',
    position: Coordinate(latitude: 46.9, longitude: 17.9),
  );
  const markB = Mark(
    sequence: 2,
    name: 'Z2',
    position: Coordinate(latitude: 46.8, longitude: 17.8),
  );

  Race notStartedRace() =>
      Race.create(id: 'race-1', name: 'Kékszalag', marks: const [markA, markB]);

  group('save / getRace round-trip', () {
    test('notStarted race a bóyáival visszaolvasható', () async {
      // ARRANGE
      final race = notStartedRace();

      // ACT
      await repository.save(race);
      final loaded = await repository.getRace('race-1');

      // ASSERT — a teljes entitás (Equatable) egyezik, a marks-szal együtt.
      expect(loaded, equals(race));
    });

    test('nem létező id-re null', () async {
      expect(await repository.getRace('nincs-ilyen'), isNull);
    });

    test('a bóyák sequence szerint növekvő sorrendben jönnek vissza', () async {
      // ARRANGE — fordított sorrendben (seq 2, majd 1) létrehozva.
      final race = Race.create(
        id: 'race-1',
        name: 'Teszt',
        marks: const [markB, markA],
      );

      // ACT
      await repository.save(race);
      final loaded = await repository.getRace('race-1');

      // ASSERT — az olvasás sequence ASC-vel normalizál.
      expect(loaded!.marks.map((m) => m.sequence).toList(), equals([1, 2]));
    });
  });

  group('upsert', () {
    test('ugyanazzal az id-vel kétszer mentve felülír, nem duplikál', () async {
      // ARRANGE
      await repository.save(notStartedRace());
      final started = notStartedRace().start(at: DateTime(2025, 6, 1, 12));

      // ACT
      await repository.save(started);

      // ASSERT — egyetlen race sor, a frissített állapottal.
      expect(await db.select(db.races).get(), hasLength(1));
      final loaded = await repository.getRace('race-1');
      expect(loaded!.status, equals(RaceStatus.active));
      expect(loaded.startedAt, equals(DateTime(2025, 6, 1, 12)));
    });

    test('a bóyaszám csökkenése törli az árva bóyákat', () async {
      // ARRANGE — 2 bója mentve.
      await repository.save(notStartedRace());

      // ACT — újra-mentés 1 bóyával.
      await repository.save(
        Race.create(id: 'race-1', name: 'Kékszalag', marks: const [markA]),
      );

      // ASSERT
      final markRows = await db.select(db.marks).get();
      expect(markRows, hasLength(1));
      expect(markRows.single.sequence, equals(1));
    });

    test('az újra-mentés nem írja felül a createdAt-et', () async {
      // ARRANGE
      await repository.save(notStartedRace());
      final createdAt = (await db.select(db.races).getSingle()).createdAt;

      // ACT — másik órájú repóval újra-mentés.
      final laterRepo = RaceRepositoryImpl(
        db,
        now: () => fixedNow.add(const Duration(days: 1)),
      );
      await laterRepo.save(notStartedRace().copyWith(name: 'Átnevezve'));

      // ASSERT — a createdAt stabil, a név frissült.
      final row = await db.select(db.races).getSingle();
      expect(row.createdAt, equals(createdAt));
      expect(row.name, equals('Átnevezve'));
    });
  });

  group('watchRaces', () {
    test('mentés után a teljes marks-szal tartalmazza a race-t', () async {
      // ACT
      await repository.save(notStartedRace());
      final races = await repository.watchRaces().first;

      // ASSERT
      expect(races, hasLength(1));
      expect(races.single.marks, equals(const [markA, markB]));
    });

    test('egy feliratkozás újra-emittál mentés és törlés után', () async {
      // ARRANGE — egyetlen streamre gyűjtjük az emissziókat.
      final emissions = <List<Race>>[];
      final sub = repository.watchRaces().listen(emissions.add);

      // ACT — minden mutáció után pumpolunk, hogy külön emisszió szülessen.
      await pumpEventQueue();
      await repository.save(notStartedRace());
      await pumpEventQueue();
      await repository.delete('race-1');
      await pumpEventQueue();
      await sub.cancel();

      // ASSERT — üres → 1 race → üres.
      expect(emissions.first, isEmpty);
      expect(
        emissions,
        contains(predicate<List<Race>>((races) => races.length == 1)),
      );
      expect(emissions.last, isEmpty);
    });
  });

  group('delete', () {
    test('cascade-del törli a bóyákat is (FK pragma ON)', () async {
      // ARRANGE
      await repository.save(notStartedRace());
      expect(await db.select(db.marks).get(), isNotEmpty);

      // ACT
      await repository.delete('race-1');

      // ASSERT — a race-szel a bóyák is eltűnnek.
      expect(await db.select(db.races).get(), isEmpty);
      expect(await db.select(db.marks).get(), isEmpty);
    });
  });

  group('state-átmenet round-trip', () {
    test('start után active-ként olvasható vissza', () async {
      // ARRANGE
      final started = notStartedRace().start(at: DateTime(2025, 6, 1, 12));

      // ACT
      await repository.save(started);
      final loaded = await repository.getRace('race-1');

      // ASSERT
      expect(loaded, equals(started));
    });

    test('roundCurrentMark után a bója roundedAt-je perzisztál', () async {
      // ARRANGE
      final racing = notStartedRace()
          .start(at: DateTime(2025, 6, 1, 12))
          .roundCurrentMark(at: DateTime(2025, 6, 1, 12, 30));

      // ACT
      await repository.save(racing);
      final loaded = await repository.getRace('race-1');

      // ASSERT
      expect(loaded, equals(racing));
      expect(loaded!.activeMarkIndex, equals(1));
      expect(
        loaded.marks.first.roundedAt,
        equals(DateTime(2025, 6, 1, 12, 30)),
      );
    });

    test('finish után finished-ként, mindkét időbélyeggel olvasható', () async {
      // ARRANGE
      final finished = notStartedRace()
          .start(at: DateTime(2025, 6, 1, 12))
          .finish(at: DateTime(2025, 6, 1, 13));

      // ACT
      await repository.save(finished);
      final loaded = await repository.getRace('race-1');

      // ASSERT
      expect(loaded, equals(finished));
      expect(loaded!.status, equals(RaceStatus.finished));
      expect(loaded.activeMarkIndex, equals(2));
    });
  });
}
