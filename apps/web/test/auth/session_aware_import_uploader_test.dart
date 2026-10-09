import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_web/api/api_failure.dart';
import 'package:foretack_web/auth/session_aware_import_uploader.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';

import '../support/fake_import.dart';

void main() {
  const database = FakePickedFile('foretack.sqlite', 1024);

  test('signals a 401 and passes the result through', () async {
    // ARRANGE
    var signals = 0;
    final inner = FakeImportUploader();
    final upload = sessionAwareImportUploader(
      inner.call,
      onUnauthorized: () => signals++,
    )(database: database, wal: null, onProgress: (_, _) {});

    // ACT
    inner.uploads.single.answer(
      const Err(ServerFailure(NotAuthenticated())),
    );
    final result = await upload.result;

    // ASSERT
    expect(signals, 1);
    expect(
      result,
      isA<Err<ImportReport, ApiFailure>>().having(
        (err) => err.error,
        'error',
        isA<ServerFailure>(),
      ),
    );
  });

  test('stays quiet on other failures and forwards the cancel', () async {
    // ARRANGE
    var signals = 0;
    final inner = FakeImportUploader();
    final start = sessionAwareImportUploader(
      inner.call,
      onUnauthorized: () => signals++,
    );

    // ACT
    final upload = start(
      database: database,
      wal: null,
      onProgress: (_, _) {},
    )..cancel();
    await upload.result;

    // ASSERT
    expect(inner.uploads.single.isCancelled, isTrue);
    expect(signals, 0);
  });
}
