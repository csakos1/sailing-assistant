import 'package:foretack_web/api/api_failure.dart';
import 'package:foretack_web/l10n/web_localizations.dart';
import 'package:foretack_web/race_import/file_size_format.dart';
import 'package:race_archive_api/race_archive_api.dart';

/// Egy sikertelen feltöltés mondata az akciók fölött (ADR 0048
/// Addendum 4 K20).
///
/// A séma-hiba nem ide jön, annak saját állapota van (13j); ha mégis ide
/// érne, az általános szerverhiba mondata áll.
String importFailureText(WebLocalizations l10n, ApiFailure failure) =>
    switch (failure) {
      NetworkFailure() => l10n.importFailedNetwork,
      ServerFailure(error: ImportRejected(:final rejection)) =>
        switch (rejection) {
          MainFileMissing() => l10n.importFailedMainFileMissing,
          NotSqliteDatabase() => l10n.importFailedNotSqlite,
          NotForetackDatabase() => l10n.importFailedNotForetack,
          SchemaTooNew() => l10n.importFailedServer,
        },
      ServerFailure(error: PayloadTooLarge(:final limitBytes)) =>
        l10n.importFailedTooLarge(formatFileSize(limitBytes)),
      ServerFailure() || UnreadableResponse() => l10n.importFailedServer,
    };
