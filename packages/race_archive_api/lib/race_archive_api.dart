/// A webes versenyarchívum HTTP-szerződése (ADR 0047 D2 + Addendum 1,
/// ADR 0048 D6 + Addendum 2, ADR 0049 D12, ADR 0051).
///
/// A web és a szerver közös DTO-i, kodekjei és a bemenetek validációja.
/// Pure Dart, `dart:io` és Flutter nélkül, hogy mindkét oldal
/// használhassa. A dekóderek `Result`-ot adnak, kivételt nem.
library;

export 'package:race_archive_api/src/api_routes.dart';
export 'package:race_archive_api/src/auth/base64url.dart';
export 'package:race_archive_api/src/auth/display_name.dart';
export 'package:race_archive_api/src/auth/password_rules.dart';
export 'package:race_archive_api/src/auth/qr_payload.dart';
export 'package:race_archive_api/src/auth/signed_messages.dart';
export 'package:race_archive_api/src/auth/user_role.dart';
export 'package:race_archive_api/src/auth/web_origin.dart';
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
export 'package:race_archive_api/src/polar/polar_codecs.dart';
export 'package:race_archive_api/src/polar/polar_stats.dart';
export 'package:race_archive_api/src/polar/race_polar_detail.dart';
export 'package:race_archive_api/src/polar/race_polar_row.dart';
export 'package:race_archive_api/src/polar/season_polar_summary.dart';
export 'package:race_archive_api/src/polar/season_polar_table.dart';
export 'package:race_archive_api/src/race/archive_track_point.dart';
export 'package:race_archive_api/src/race/archived_race_codec.dart'
    show decodeArchivedRace, encodeArchivedRace;
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
