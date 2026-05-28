import 'package:data/src/persistence/app_database.dart';
import 'package:data/src/persistence/repositories/telemetry_logger_impl.dart';
import 'package:domain/domain.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    // A TelemetryRecords.raceId FK-ja (PRAGMA foreign_keys = ON) miatt kell
    // egy szülő race, különben minden telemetria-insert FK-sértés.
    await db
        .into(db.races)
        .insert(
          RacesCompanion.insert(
            id: 'race-1',
            name: 'Teszt',
            statusIndex: RaceStatus.notStarted,
            createdAt: DateTime(2025, 6, 1, 10),
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  TelemetryRecord rec(int n) => TelemetryRecord(
    raceId: 'race-1',
    timestamp: DateTime(2025, 6, 1, 12, 0, n),
    rawSentence: 'sentence-$n',
  );

  Future<List<TelemetryRow>> storedRows() =>
      db.select(db.telemetryRecords).get();

  group('buffer-méret trigger', () {
    test('a méret eléréséig nem ír, elérésekor batch-ben kiír', () async {
      // ARRANGE — hosszú flush-interval, hogy csak a méret triggereljen.
      final logger = TelemetryLoggerImpl(
        db,
        maxBufferSize: 3,
        flushInterval: const Duration(seconds: 30),
      );

      // ACT + ASSERT
      await logger.log(rec(1));
      await logger.log(rec(2));
      expect(await storedRows(), isEmpty); // 2 < 3

      await logger.log(rec(3)); // eléri a 3-at -> flush
      expect(await storedRows(), hasLength(3));
    });
  });

  group('flush-timer trigger', () {
    test('a timer lejártakor a pufferelt mondatok kiíródnak', () async {
      // ARRANGE — rövid valós interval (lásd a commit-üzenet indoklását a
      // fakeAsync mellőzéséről).
      final logger = TelemetryLoggerImpl(
        db,
        flushInterval: const Duration(milliseconds: 20),
      );

      // ACT
      await logger.log(rec(1));
      await logger.log(rec(2));
      await Future<void>.delayed(const Duration(milliseconds: 60));

      // ASSERT
      expect(await storedRows(), hasLength(2));
      await logger.dispose();
    });
  });

  group('dispose', () {
    test('a függőben lévő puffert kiírja', () async {
      // ARRANGE
      final logger = TelemetryLoggerImpl(
        db,
        flushInterval: const Duration(seconds: 30),
      );

      // ACT + ASSERT
      await logger.log(rec(1));
      await logger.log(rec(2));
      expect(await storedRows(), isEmpty); // a timer még nem járt le

      await logger.dispose();
      expect(await storedRows(), hasLength(2));
    });

    test('üres bufferrel no-op, nem dob', () async {
      final logger = TelemetryLoggerImpl(db);

      await logger.dispose();

      expect(await storedRows(), isEmpty);
    });

    test('dispose után a log nem ír többé', () async {
      final logger = TelemetryLoggerImpl(
        db,
        flushInterval: const Duration(seconds: 30),
      );

      await logger.dispose();
      await logger.log(rec(1)); // eldobva
      await logger.dispose(); // nincs mit kiírni

      expect(await storedRows(), isEmpty);
    });
  });

  group('mapper', () {
    test(
      'a kiírt sor a TelemetryRecord mezőit tükrözi, decodedJson null',
      () async {
        // ARRANGE
        final logger = TelemetryLoggerImpl(
          db,
          flushInterval: const Duration(seconds: 30),
        );
        final timestamp = DateTime(2025, 6, 1, 12, 30);
        const sentence = r'$IIMWV,045.0,R,12.3,N,A*28';

        // ACT
        await logger.log(
          TelemetryRecord(
            raceId: 'race-1',
            timestamp: timestamp,
            rawSentence: sentence,
          ),
        );
        await logger.dispose();

        // ASSERT
        final row = (await storedRows()).single;
        expect(row.raceId, equals('race-1'));
        expect(row.timestamp, equals(timestamp));
        expect(row.rawSentence, equals(sentence));
        expect(row.decodedJson, isNull);
      },
    );
  });
}
