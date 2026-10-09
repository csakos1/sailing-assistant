import 'dart:convert';
import 'dart:io';

import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:meta/meta.dart';
import 'package:shared/shared.dart';
import 'package:web_server/src/polar/polar_reference.dart';
import 'package:web_server/src/polar/stw_corrections_json.dart';

/// A polár induláskori állapota (ADR 0049 D5, Addendum 4 U1).
///
/// Sealed: a kompozíciós gyökér kimerítő `switch`-csel dönti el, köt-e be
/// polár-számítást, vagy a végpontok `PolarUnavailable`-t adnak.
@immutable
sealed class PolarSetup {
  const PolarSetup();
}

/// A polár és a korrekciók betöltődtek.
final class PolarReady extends PolarSetup {
  /// Kész polár a [reference]-szel.
  const PolarReady(this.reference);

  /// A polár, a korrekciók és az ujjlenyomat.
  final PolarReference reference;
}

/// A polár nem elérhető; a [reason] a szerver naplójába kerül.
final class PolarMissing extends PolarSetup {
  /// Hiányzó polár a [reason] okkal.
  const PolarMissing(this.reason);

  /// Magyar mondat: miért nem elérhető.
  final String reason;
}

/// Egy fájl bájtjainak olvasója; a tesztek memóriából adják.
typedef ReadFileBytes = Future<List<int>> Function(String path);

/// A `--polar` és a `--stw-corrections` fájl betöltése (U1).
///
/// Bármelyik hibája [PolarMissing]: a korrekció-fájl hibája nem esik
/// vissza csendben a korrekció nélküli számításra. A [correctionsPath]
/// hiánya üres korrekció-listát jelent.
Future<PolarSetup> loadPolarSetup({
  required String? polarPath,
  required String? correctionsPath,
  ReadFileBytes readBytes = _readFileBytes,
}) async {
  if (polarPath == null) return const PolarMissing('nincs --polar kapcsoló');
  final polarBytes = await _tryRead(readBytes, polarPath);
  final polarText = polarBytes == null ? null : _tryDecode(polarBytes);
  if (polarBytes == null || polarText == null) {
    return PolarMissing('a polár nem olvasható: $polarPath');
  }
  final Polar polar;
  switch (parseForetackPolar(polarText)) {
    case Ok(:final value):
      polar = value;
    case Err(:final error):
      return PolarMissing('a polár hibás ($polarPath): ${_describe(error)}');
  }

  var corrections = const <StwCorrection>[];
  if (correctionsPath != null) {
    final bytes = await _tryRead(readBytes, correctionsPath);
    final text = bytes == null ? null : _tryDecode(bytes);
    if (text == null) {
      return PolarMissing('a korrekció-fájl nem olvasható: $correctionsPath');
    }
    switch (parseStwCorrections(text)) {
      case Ok(:final value):
        corrections = value;
      case Err(:final error):
        return PolarMissing('a korrekció-fájl hibás: $error');
    }
  }
  return PolarReady(
    PolarReference(
      polar: polar,
      corrections: corrections,
      fingerprint: polarFingerprint(
        polarBytes: polarBytes,
        corrections: corrections,
      ),
    ),
  );
}

String _describe(PolarLoadError error) => switch (error) {
  PolarAssetMissing() => 'nincs meg',
  PolarEmpty() => 'üres',
  PolarMalformedHeader() => 'hibás fejléc',
  PolarMalformedRow(:final lineNumber, :final reason) =>
    'hibás sor ($lineNumber.): $reason',
  PolarNoUsableCells() => 'nincs használható cella',
};

Future<List<int>?> _tryRead(ReadFileBytes readBytes, String path) async {
  try {
    return await readBytes(path);
  } on FileSystemException {
    return null;
  }
}

String? _tryDecode(List<int> bytes) {
  try {
    return utf8.decode(bytes);
  } on FormatException {
    return null;
  }
}

Future<List<int>> _readFileBytes(String path) => File(path).readAsBytes();
