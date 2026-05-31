import 'package:data/src/persistence/app_database.dart';
import 'package:data/src/persistence/repositories/settings_repository_impl.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
