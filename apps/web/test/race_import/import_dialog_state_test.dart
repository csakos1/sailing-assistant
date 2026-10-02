import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_web/api/api_failure.dart';
import 'package:foretack_web/race_import/import_dialog_state.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';

import '../support/fake_import.dart';

void main() {
  const database = FakePickedFile('foretack.sqlite', 4000);
  const wal = FakePickedFile('foretack.sqlite-wal', 1000);
  const report = ImportReport(
    added: [],
    updated: [],
    skipped: [],
    warnings: [],
  );

  Uploading uploadingBoth() =>
      const ChoosingFiles(database: database, wal: wal).startUpload()!;

  group('ChoosingFiles', () {
    test('cannot upload without the main database file', () {
      // ARRANGE
      const state = ChoosingFiles(wal: wal);

      // ACT + ASSERT
      expect(state.canUpload, isFalse);
      expect(state.startUpload(), isNull);
    });

    test('starts the upload with both files and their summed size', () {
      // ACT
      final uploading = uploadingBoth();

      // ASSERT
      expect(uploading.database, same(database));
      expect(uploading.wal, same(wal));
      expect(uploading.sentBytes, 0);
      expect(uploading.totalBytes, 5000);
      expect(uploading.isProcessing, isFalse);
    });

    test('a new file clears the failure of the previous attempt', () {
      // ARRANGE
      const state = ChoosingFiles(
        database: database,
        failure: NetworkFailure('x'),
      );

      // ACT
      final withNewWal = state.withWal(wal);
      final withNewDatabase = state.withDatabase(database);

      // ASSERT
      expect(withNewWal.failure, isNull);
      expect(withNewWal.database, same(database));
      expect(withNewDatabase.failure, isNull);
    });
  });

  group('Uploading.withProgress', () {
    test('takes the real total of the multipart body', () {
      // ACT
      final state = uploadingBoth().withProgress(2500, 5200);

      // ASSERT
      expect(state.sentBytes, 2500);
      expect(state.totalBytes, 5200);
      expect(state.fraction, closeTo(2500 / 5200, 1e-9));
    });

    test('never moves backwards', () {
      // ACT
      final state = uploadingBoth()
          .withProgress(3000, 5200)
          .withProgress(1000, 5200);

      // ASSERT
      expect(state.sentBytes, 3000);
    });

    test('keeps the estimate when the total is unknown', () {
      // ACT
      final state = uploadingBoth().withProgress(1000, 0);

      // ASSERT
      expect(state.totalBytes, 5000);
      expect(state.sentBytes, 1000);
    });

    test('a smaller total than the bytes sent does not throw', () {
      // ACT
      final state = uploadingBoth()
          .withProgress(4800, 5000)
          .withProgress(4900, 4500);

      // ASSERT
      expect(state.sentBytes, 4500);
      expect(state.isProcessing, isTrue);
    });

    test('is processing once every byte is out', () {
      // ACT
      final state = uploadingBoth().withProgress(5200, 5200);

      // ASSERT
      expect(state.isProcessing, isTrue);
      expect(state.fraction, 1);
    });

    test('counts the first bytes towards the main database file', () {
      // ACT
      final early = uploadingBoth().withProgress(1500, 5200);
      final pastDatabase = uploadingBoth().withProgress(4800, 5200);

      // ASSERT
      expect(early.databaseSentBytes, 1500);
      expect(pastDatabase.databaseSentBytes, 4000);
    });
  });

  group('Uploading.finish', () {
    test('a report finishes the import', () {
      // ACT
      final next = uploadingBoth().finish(const Ok(report));

      // ASSERT
      expect(next, isA<ImportFinished>());
      expect((next as ImportFinished).report, report);
    });

    test('a newer schema shows both versions', () {
      // ARRANGE
      const outcome = Err<ImportReport, ApiFailure>(
        ServerFailure(
          ImportRejected(SchemaTooNew(fileVersion: 9, serverVersion: 8)),
        ),
      );

      // ACT
      final next = uploadingBoth().finish(outcome);

      // ASSERT
      expect(next, isA<SchemaRejected>());
      final rejected = next as SchemaRejected;
      expect(rejected.fileName, 'foretack.sqlite');
      expect(rejected.fileVersion, 9);
      expect(rejected.serverVersion, 8);
    });

    test('any other failure returns to the choice with the files kept', () {
      // ARRANGE
      const failure = ServerFailure(ImportRejected(NotSqliteDatabase()));

      // ACT
      final next = uploadingBoth().finish(const Err(failure));

      // ASSERT
      expect(next, isA<ChoosingFiles>());
      final choosing = next as ChoosingFiles;
      expect(choosing.database, same(database));
      expect(choosing.wal, same(wal));
      expect(choosing.failure, failure);
      expect(choosing.canUpload, isTrue);
    });
  });
}
