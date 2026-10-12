import 'package:data/src/persistence/app_database.dart';
import 'package:data/src/persistence/repositories/settings_repository_impl.dart';
import 'package:domain/domain.dart';
import 'package:drift/native.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;
  late SettingsRepositoryImpl repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = SettingsRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('readActiveRaceId', () {
    test('üres tárból null', () async {
      expect(await repository.readActiveRaceId(), isNull);
    });

    test('írás után visszaolvasható', () async {
      // ACT
      await repository.writeActiveRaceId('race-1');

      // ASSERT
      expect(await repository.readActiveRaceId(), equals('race-1'));
    });
  });

  group('writeActiveRaceId', () {
    test('upsert: kétszeri írás felülír, nem duplikál', () async {
      // ARRANGE
      await repository.writeActiveRaceId('race-1');

      // ACT
      await repository.writeActiveRaceId('race-2');

      // ASSERT — a friss érték, és egyetlen sor a Settings táblában.
      expect(await repository.readActiveRaceId(), equals('race-2'));
      expect(await db.select(db.settings).get(), hasLength(1));
    });

    test('null törli a tárolt id-t (delete-on-unset)', () async {
      // ARRANGE
      await repository.writeActiveRaceId('race-1');

      // ACT
      await repository.writeActiveRaceId(null);

      // ASSERT — null olvasás, és a sor ténylegesen eltűnt.
      expect(await repository.readActiveRaceId(), isNull);
      expect(await db.select(db.settings).get(), isEmpty);
    });

    test('null üres tárra no-op, nem dob', () async {
      // ACT / ASSERT
      await repository.writeActiveRaceId(null);
      expect(await repository.readActiveRaceId(), isNull);
    });
  });
  group('instruments race choice', () {
    test('üres tárból null', () async {
      expect(await repository.readInstrumentsRaceChoice(), isNull);
    });

    test('írás után visszaolvasható, a nap megmarad', () async {
      // ARRANGE
      final choice = InstrumentsRaceChoice(
        raceId: 'race-1',
        chosenOnLocalDay: DateTime(2026, 7, 30),
      );

      // ACT
      await repository.writeInstrumentsRaceChoice(choice);

      // ASSERT
      expect(await repository.readInstrumentsRaceChoice(), equals(choice));
    });

    test('null törli, az aktív race id-je megmarad', () async {
      // ARRANGE
      await repository.writeActiveRaceId('race-1');
      await repository.writeInstrumentsRaceChoice(
        InstrumentsRaceChoice(
          raceId: 'race-2',
          chosenOnLocalDay: DateTime(2026, 7, 30),
        ),
      );

      // ACT
      await repository.writeInstrumentsRaceChoice(null);

      // ASSERT
      expect(await repository.readInstrumentsRaceChoice(), isNull);
      expect(await repository.readActiveRaceId(), equals('race-1'));
    });

    for (final stored in [
      'nem json',
      '[]',
      '{"raceId":"","day":"2026-07-30"}',
      '{"raceId":"race-1"}',
      '{"raceId":"race-1","day":"2026-7-30"}',
      '{"raceId":"race-1","day":"2026-02-31"}',
    ]) {
      test('olvashatatlan érték null: $stored', () async {
        // ARRANGE
        await db
            .into(db.settings)
            .insert(
              SettingsCompanion.insert(
                key: 'instruments_race_choice',
                value: stored,
              ),
            );

        // ACT / ASSERT
        expect(await repository.readInstrumentsRaceChoice(), isNull);
      });
    }
  });
}
