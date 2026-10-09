import 'dart:convert';

import 'package:domain/domain.dart';
import 'package:shared/shared.dart';

// Időzónás ISO-pillanat: a `Z` vagy a `±hh:mm` (`±hhmm`) végződés kötelező,
// hogy a nap-határ ne függjön a szerver zónájától (ADR 0049 D6).
final RegExp _zonedInstant = RegExp(r'(Z|[+-]\d{2}:?\d{2})$');

/// A `--stw-corrections` fájl tartalma → korrekciók (ADR 0049 D6,
/// Addendum 4 U1).
///
/// A fájl egy JSON-tömb: `[{"from": "2026-07-20T00:00:00+02:00",
/// "factor": 1.081}]`. Untrusted bemenet, ezért `Result`: a hiba a
/// szerver naplójába kerülő magyar mondat, a hibás elem indexével.
Result<List<StwCorrection>, String> parseStwCorrections(String text) {
  final Object? json;
  try {
    json = jsonDecode(text);
  } on FormatException catch (error) {
    return Err('nem JSON: ${error.message}');
  }
  if (json is! List<Object?>) return const Err('JSON-tömb kell');
  final corrections = <StwCorrection>[];
  for (final (index, item) in json.indexed) {
    if (item is! Map<String, Object?>) {
      return Err('[$index]: objektum kell');
    }
    final from = _instantOf(item['from']);
    if (from == null) {
      return Err('[$index].from: időzónás ISO-pillanat kell');
    }
    final factor = item['factor'];
    if (factor is! num || !factor.isFinite || factor <= 0) {
      return Err('[$index].factor: véges, pozitív szám kell');
    }
    corrections.add(StwCorrection(from: from, factor: factor.toDouble()));
  }
  return Ok(List.unmodifiable(corrections));
}

DateTime? _instantOf(Object? value) {
  if (value is! String || !_zonedInstant.hasMatch(value)) return null;
  return DateTime.tryParse(value);
}
