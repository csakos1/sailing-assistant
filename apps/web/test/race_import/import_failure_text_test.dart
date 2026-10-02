import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_web/api/api_failure.dart';
import 'package:foretack_web/l10n/web_localizations.dart';
import 'package:foretack_web/race_import/import_failure_text.dart';
import 'package:race_archive_api/race_archive_api.dart';

void main() {
  final l10n = lookupWebLocalizations(const Locale('hu'));

  group('importFailureText', () {
    test('names a lost connection', () {
      expect(
        importFailureText(l10n, const NetworkFailure('x')),
        l10n.importFailedNetwork,
      );
    });

    test('names each rejection of the file', () {
      expect(
        importFailureText(
          l10n,
          const ServerFailure(ImportRejected(NotSqliteDatabase())),
        ),
        l10n.importFailedNotSqlite,
      );
      expect(
        importFailureText(
          l10n,
          const ServerFailure(ImportRejected(NotForetackDatabase())),
        ),
        l10n.importFailedNotForetack,
      );
      expect(
        importFailureText(
          l10n,
          const ServerFailure(ImportRejected(MainFileMissing())),
        ),
        l10n.importFailedMainFileMissing,
      );
    });

    test('gives the size limit of a too large upload', () {
      // ACT: 4 GiB
      final text = importFailureText(
        l10n,
        const ServerFailure(PayloadTooLarge(4294967296)),
      );

      // ASSERT
      expect(text, contains('4,0 GB'));
    });

    test('falls back to the server sentence for anything else', () {
      expect(
        importFailureText(l10n, const ServerFailure(InternalError())),
        l10n.importFailedServer,
      );
      expect(
        importFailureText(l10n, const UnreadableResponse(502)),
        l10n.importFailedServer,
      );
    });
  });
}
