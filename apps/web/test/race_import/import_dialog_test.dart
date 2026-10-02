import 'dart:convert';

import 'package:domain/domain.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_web/api/api_failure.dart';
import 'package:foretack_web/api/archive_api_client.dart';
import 'package:foretack_web/app/api_providers.dart';
import 'package:foretack_web/app/foretack_web_app.dart';
import 'package:foretack_web/app/leave_warning_provider.dart';
import 'package:foretack_web/race_import/import_dialog.dart';
import 'package:foretack_web/race_import/import_providers.dart';
import 'package:foretack_web/race_import/picked_file.dart';
import 'package:foretack_web/race_import/widgets/import_file_cell.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';

import '../support/fake_import.dart';
import '../support/sample_summaries.dart';

// A feltoltes-dialogus a teljes appon at: naplo -> Feltoltes gomb. A
// valaszto es a feltolto fake, a naplot egy MockClient szolgalja ki.

void main() {
  const database = FakePickedFile('foretack.sqlite', 5033165);
  const wal = FakePickedFile('foretack.sqlite-wal', 319488);

  late FakeImportUploader uploader;
  late List<PickedFile?> picks;
  late int logLoads;

  Future<void> pumpApp(WidgetTester tester) async {
    uploader = FakeImportUploader();
    picks = [];
    logLoads = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          archiveApiClientProvider.overrideWithValue(
            ArchiveApiClient(
              MockClient((request) async {
                logLoads++;
                return http.Response.bytes(
                  utf8.encode(
                    jsonEncode(
                      encodeRaceSummaries([
                        telemetrySummary(
                          'lelle',
                          start: DateTime(2026, 8, 22, 11),
                        ),
                      ]),
                    ),
                  ),
                  200,
                );
              }),
              baseUri: Uri.parse('http://localhost/'),
            ),
          ),
          importFilePickerProvider.overrideWithValue(
            () async => picks.removeAt(0),
          ),
          importUploaderProvider.overrideWithValue(uploader.call),
        ],
        child: const ForetackWebApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder inDialog(String text) => find.descendant(
    of: find.byType(ImportDialog),
    matching: find.text(text),
  );

  Future<void> openDialog(WidgetTester tester) async {
    await tester.tap(find.text('Feltöltés'));
    await tester.pumpAndSettle();
  }

  Future<void> chooseBothFiles(WidgetTester tester) async {
    picks.addAll([database, wal]);
    // A fo fajl cellaja all elol, a -wal cellaja masodiknak.
    await tester.tap(find.byType(ImportFileCell).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ImportFileCell).last);
    await tester.pumpAndSettle();
  }

  // Feltoltes kozben a forgo vegtelen animacio: pumpAndSettle helyett.
  Future<void> startUpload(WidgetTester tester) async {
    await tester.tap(inDialog('Feltöltés'));
    await tester.pump();
  }

  testWidgets('upload stays disabled until the main file is chosen', (
    tester,
  ) async {
    // ARRANGE
    await pumpApp(tester);
    await openDialog(tester);

    // ACT
    await tester.tap(inDialog('Feltöltés'));
    await tester.pump();

    // ASSERT
    expect(find.text('Adatbázis feltöltése'), findsOneWidget);
    expect(inDialog('Nincs kiválasztva'), findsNWidgets(2));
    expect(uploader.uploads, isEmpty);
  });

  testWidgets('uploads both chosen files and shows the progress', (
    tester,
  ) async {
    // ARRANGE
    await pumpApp(tester);
    await openDialog(tester);
    await chooseBothFiles(tester);
    expect(inDialog('foretack.sqlite'), findsOneWidget);
    expect(inDialog('4,8 MB'), findsOneWidget);
    expect(inDialog('312 KB'), findsOneWidget);

    // ACT
    await startUpload(tester);
    uploader.onProgress!(2700000, 5400000);
    await tester.pump();

    // ASSERT
    final upload = uploader.uploads.single;
    expect(upload.database, same(database));
    expect(upload.wal, same(wal));
    expect(inDialog('50 %'), findsOneWidget);
    expect(inDialog('Feltöltés…'), findsOneWidget);

    // ACT: minden bajt kiment, a szerver dolgozik
    uploader.onProgress!(5400000, 5400000);
    await tester.pump();

    // ASSERT
    expect(inDialog('FELDOLGOZÁS'), findsOneWidget);
  });

  testWidgets('shows the report and refreshes the log on close', (
    tester,
  ) async {
    // ARRANGE
    await pumpApp(tester);
    await openDialog(tester);
    await chooseBothFiles(tester);
    await startUpload(tester);

    // ACT
    uploader.uploads.single.answer(
      Ok(
        ImportReport(
          added: [
            ImportedRace(
              id: 'a',
              name: 'Evadzaro Kupa',
              finishedAt: DateTime(2026, 9, 26, 17).toUtc(),
            ),
          ],
          updated: const [],
          skipped: const [
            SkippedRace(
              id: 's',
              name: 'Tihanyi hajnal',
              status: RaceStatus.active,
            ),
          ],
          warnings: const [ImportWarning.walIgnored],
        ),
      ),
    );
    await tester.pumpAndSettle();

    // ASSERT
    expect(find.text('Feltöltés kész'), findsOneWidget);
    expect(find.text('ÚJ'), findsOneWidget);
    expect(find.text('KIMARADT · NEM BEFEJEZETT'), findsOneWidget);
    expect(find.text('FRISSÜLT'), findsNothing);
    expect(find.text('Evadzaro Kupa'), findsOneWidget);
    expect(find.text('26'), findsOneWidget);
    expect(find.text('––'), findsOneWidget);
    expect(
      find.text(
        'A WAL-fájl érvénytelen volt, ezért csak a fő fájl adatai kerültek be.',
      ),
      findsOneWidget,
    );
    expect(logLoads, 1);

    // ACT
    await tester.tap(find.text('Bezárás'));
    await tester.pumpAndSettle();

    // ASSERT
    expect(find.byType(ImportDialog), findsNothing);
    expect(logLoads, 2);
  });

  testWidgets('shows both versions when the schema is newer', (tester) async {
    // ARRANGE
    await pumpApp(tester);
    await openDialog(tester);
    await chooseBothFiles(tester);
    await startUpload(tester);

    // ACT
    uploader.uploads.single.answer(
      const Err(
        ServerFailure(
          ImportRejected(SchemaTooNew(fileVersion: 9, serverVersion: 8)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // ASSERT
    expect(find.text('Az app újabb adatbázis-verziót használ'), findsOneWidget);
    expect(find.text('SÉMA v9'), findsOneWidget);
    expect(find.text('SÉMA v8'), findsOneWidget);

    // ACT: bezaras utan a naplo nem frissul
    await tester.tap(find.text('Bezárás'));
    await tester.pumpAndSettle();

    // ASSERT
    expect(logLoads, 1);
  });

  testWidgets('keeps the files and explains a failed upload', (tester) async {
    // ARRANGE
    await pumpApp(tester);
    await openDialog(tester);
    await chooseBothFiles(tester);
    await startUpload(tester);

    // ACT
    uploader.uploads.single.answer(const Err(NetworkFailure('offline')));
    await tester.pumpAndSettle();

    // ASSERT
    expect(
      find.text(
        'A feltöltés megszakadt. Ellenőrizd a kapcsolatot, és próbáld újra.',
      ),
      findsOneWidget,
    );
    expect(inDialog('foretack.sqlite'), findsOneWidget);

    // ACT: ujraproba egy kattintassal
    await startUpload(tester);

    // ASSERT
    expect(uploader.uploads, hasLength(2));
  });

  testWidgets('Enter starts the upload once the main file is chosen', (
    tester,
  ) async {
    // ARRANGE
    await pumpApp(tester);
    await openDialog(tester);
    picks.add(database);
    await tester.tap(find.byType(ImportFileCell).first);
    await tester.pumpAndSettle();

    // ACT: a fokusz a Feltoltes cellan all (13f)
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    // ASSERT
    expect(uploader.uploads, hasLength(1));
    expect(uploader.uploads.single.wal, isNull);
  });

  testWidgets('names the size limit of a too large upload', (tester) async {
    // ARRANGE
    await pumpApp(tester);
    await openDialog(tester);
    await chooseBothFiles(tester);
    await startUpload(tester);

    // ACT
    uploader.uploads.single.answer(
      const Err(ServerFailure(PayloadTooLarge(4294967296))),
    );
    await tester.pumpAndSettle();

    // ASSERT
    expect(
      find.text('A fájl nagyobb a szerver korlátjánál (4,0 GB).'),
      findsOneWidget,
    );
  });

  testWidgets('cancel during the upload aborts it and closes the dialog', (
    tester,
  ) async {
    // ARRANGE
    await pumpApp(tester);
    await openDialog(tester);
    await chooseBothFiles(tester);
    await startUpload(tester);
    final leaveWarning = ProviderScope.containerOf(
      tester.element(find.byType(ImportDialog)),
    ).read(leaveWarningProvider);
    expect(leaveWarning.shouldWarn, isTrue);

    // ACT
    await tester.tap(inDialog('Mégse'));
    await tester.pumpAndSettle();

    // ASSERT
    expect(uploader.uploads.single.isCancelled, isTrue);
    expect(find.byType(ImportDialog), findsNothing);
    expect(leaveWarning.shouldWarn, isFalse);
    expect(logLoads, 1);
  });
}
