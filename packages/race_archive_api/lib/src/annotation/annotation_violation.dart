import 'package:race_archive_api/src/validation/input_field.dart';
import 'package:race_archive_api/src/validation/input_violation.dart';

// A v1 annotáció hiba-típusainak régi nevei (ADR 0047 Addendum 1 A6).
//
// Az ADR 0048 Addendum 2 H5 óta a mező és a szabálysértés közös
// (`InputField`, `InputViolation`). A v1 nevek típus-aliasként élnek, hogy
// a `web_server` az S5b-3-ig változatlanul forduljon; az S5b-3 törli őket.

/// A v1 annotáció mezői: az [InputField] régi neve.
typedef AnnotationField = InputField;

/// A v1 annotáció szabálysértése: az [InputViolation] régi neve.
typedef AnnotationViolation = InputViolation;
