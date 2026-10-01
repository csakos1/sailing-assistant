/// A webes versenyarchívum HTTP-szerződése (ADR 0047 D2 + Addendum 1,
/// ADR 0048 D6 + Addendum 2).
///
/// A web és a szerver közös DTO-i, kodekjei és a bemenetek validációja. A
/// v1 (annotáció, `RaceListItem`, `LegacyRaceDetail`) az S5b-3-ig a v2
/// mellett él. Pure Dart, `dart:io` és Flutter nélkül, hogy mindkét oldal
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
export 'package:race_archive_api/src/record/calendar_date.dart';
export 'package:race_archive_api/src/record/manual_race_codecs.dart'
    show decodeManualRaceRequest, encodeManualRaceRequest;
export 'package:race_archive_api/src/record/manual_race_input.dart';
export 'package:race_archive_api/src/record/manual_race_request.dart';
export 'package:race_archive_api/src/record/placing.dart';
export 'package:race_archive_api/src/record/race_detail.dart';
export 'package:race_archive_api/src/record/race_detail_codec.dart';
export 'package:race_archive_api/src/record/race_origin.dart';
export 'package:race_archive_api/src/record/race_result.dart';
export 'package:race_archive_api/src/record/race_result_input.dart';
export 'package:race_archive_api/src/record/race_stats.dart';
export 'package:race_archive_api/src/record/race_summary.dart';
export 'package:race_archive_api/src/record/result_codecs.dart'
    show
        decodeRaceResult,
        decodeRaceResultInput,
        encodeRaceResult,
        encodeRaceResultInput;
export 'package:race_archive_api/src/record/stats_window.dart';
export 'package:race_archive_api/src/record/summary_codecs.dart'
    show
        decodeRaceSummaries,
        decodeRaceSummary,
        encodeRaceSummaries,
        encodeRaceSummary;
export 'package:race_archive_api/src/record/validate_manual_race_input.dart';
export 'package:race_archive_api/src/record/validate_manual_race_request.dart';
export 'package:race_archive_api/src/record/validate_race_result_input.dart';
export 'package:race_archive_api/src/validation/input_field.dart';
export 'package:race_archive_api/src/validation/input_violation.dart';
