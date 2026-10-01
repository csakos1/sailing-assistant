/// A webes versenyarchívum HTTP-szerződése (ADR 0047 D2 + Addendum 1).
///
/// A web és a szerver közös DTO-i, kodekjei és az eredmény-adatok
/// validációja. Pure Dart, `dart:io` és Flutter nélkül, hogy mindkét oldal
/// használhassa. A dekóderek `Result`-ot adnak, kivételt nem.
library;

export 'package:race_archive_api/src/annotation/annotation_codecs.dart'
    show
        decodeRaceAnnotation,
        decodeRaceAnnotationInput,
        encodeRaceAnnotation,
        encodeRaceAnnotationInput;
export 'package:race_archive_api/src/annotation/annotation_violation.dart';
export 'package:race_archive_api/src/annotation/race_annotation.dart';
export 'package:race_archive_api/src/annotation/race_annotation_input.dart';
export 'package:race_archive_api/src/annotation/validate_race_annotation_input.dart';
export 'package:race_archive_api/src/api_routes.dart';
export 'package:race_archive_api/src/error/api_error.dart';
export 'package:race_archive_api/src/import/import_rejection.dart'
    show
        ImportRejection,
        MainFileMissing,
        NotForetackDatabase,
        NotSqliteDatabase,
        SchemaTooNew;
export 'package:race_archive_api/src/import/import_report.dart';
export 'package:race_archive_api/src/json/decode_error.dart';
export 'package:race_archive_api/src/race/archive_track_point.dart';
export 'package:race_archive_api/src/race/archived_race_codec.dart'
    show decodeArchivedRace, encodeArchivedRace;
export 'package:race_archive_api/src/race/legacy_race_detail.dart';
export 'package:race_archive_api/src/race/race_list_item.dart';
