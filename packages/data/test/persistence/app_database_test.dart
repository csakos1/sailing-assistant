import 'package:data/src/persistence/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('AppDatabase scaffold', () {
    test('üres adatbázisként nyílik — nincs race', () async {
      // ACT
      final races = await db.select(db.races).get();

      // ASSERT
      expect(races, isEmpty);
    });

    test('a beforeOpen bekapcsolja a foreign_keys PRAGMA-t', () async {
      // ACT
      final row = await db.customSelect('PRAGMA foreign_keys').getSingle();

      // ASSERT — 1 = ON, e nélkül a cascade delete némán nem futna
      expect(row.data.values.first, 1);
    });
  });
}
