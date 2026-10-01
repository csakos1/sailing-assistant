import 'package:race_archive_api/src/json/json_reader.dart';
import 'package:race_archive_api/src/validation/input_field.dart';
import 'package:race_archive_api/src/validation/input_violation.dart';

// A szabálysértés kodekje (ADR 0048 Addendum 2 H5). Belső fájl: az
// `ApiError` kodekje hívja. A v1 kódjai és mezőnevei változatlanok.

/// [InputViolation] → JSON: `{field, code}`.
Map<String, Object?> encodeInputViolation(InputViolation violation) =>
    <String, Object?>{
      'field': violation.field.name,
      'code': switch (violation) {
        ValueNotPositive() => _valueNotPositiveCode,
        PlaceExceedsFleetSize() => _placeExceedsFleetSizeCode,
        FinishNotAfterStart() => _finishNotAfterStartCode,
        ValueNegative() => _valueNegativeCode,
        ValueEmpty() => _valueEmptyCode,
      },
    };

/// JSON-elem → [InputViolation], a `list` olvasó elem-callbackjeként.
InputViolation readInputViolation(Object? item, String path) {
  final reader = JsonReader.at(item, path);
  final field = reader.enumByName('field', InputField.values);
  return switch (reader.string('code')) {
    _valueNotPositiveCode => ValueNotPositive(field),
    _placeExceedsFleetSizeCode => PlaceExceedsFleetSize(field),
    // A mezőt a típus rögzíti; egy más mezővel érkező kód hibás bemenet.
    _finishNotAfterStartCode when field == InputField.officialFinish =>
      const FinishNotAfterStart(),
    _valueNegativeCode => ValueNegative(field),
    _valueEmptyCode => ValueEmpty(field),
    _ => JsonReader.failAt(reader.childPath('code'), 'violation code'),
  };
}

const String _valueNotPositiveCode = 'valueNotPositive';
const String _placeExceedsFleetSizeCode = 'placeExceedsFleetSize';
const String _finishNotAfterStartCode = 'finishNotAfterStart';
const String _valueNegativeCode = 'valueNegative';
const String _valueEmptyCode = 'valueEmpty';
