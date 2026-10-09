import 'package:domain/domain.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';
import 'package:web_server/src/polar/stw_corrections_json.dart';

// Az Ok == a lista azonossagat nezne, ezert az ertek kerul ossze.
List<StwCorrection> valueOf(Result<List<StwCorrection>, String> result) =>
    switch (result) {
      Ok(:final value) => value,
      Err(:final error) => throw StateError('Ok-t vartunk: $error'),
    };

String errorOf(Result<List<StwCorrection>, String> result) => switch (result) {
  Ok() => throw StateError('Err-t vartunk'),
  Err(:final error) => error,
};

void main() {
  group('parseStwCorrections', () {
    test('reads zoned instants and factors', () {
      // ACT
      final corrections = valueOf(
        parseStwCorrections(
          '[{"from": "2026-07-20T00:00:00+02:00", "factor": 1.081},'
          ' {"from": "2026-09-01T00:00:00Z", "factor": 1}]',
        ),
      );

      // ASSERT
      expect(corrections, [
        StwCorrection(from: DateTime.utc(2026, 7, 19, 22), factor: 1.081),
        StwCorrection(from: DateTime.utc(2026, 9), factor: 1),
      ]);
    });

    test('accepts an empty list', () {
      expect(valueOf(parseStwCorrections('[]')), isEmpty);
    });

    test('rejects text that is no JSON array', () {
      expect(errorOf(parseStwCorrections('{nem json')), startsWith('nem JSON'));
      expect(errorOf(parseStwCorrections('{}')), 'JSON-tömb kell');
    });

    test('rejects an instant without a zone', () {
      // ACT
      final error = errorOf(
        parseStwCorrections(
          '[{"from": "2026-07-20T00:00:00", "factor": 1.081}]',
        ),
      );

      // ASSERT
      expect(error, '[0].from: időzónás ISO-pillanat kell');
    });

    test('rejects a missing or non-positive factor', () {
      for (final factor in ['0', '-1.1', '"1.08"', 'null']) {
        final json = '[{"from": "2026-07-20T00:00:00Z", "factor": $factor}]';
        expect(
          errorOf(parseStwCorrections(json)),
          '[0].factor: véges, pozitív szám kell',
          reason: factor,
        );
      }
    });
  });
}
