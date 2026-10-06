import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:web_server/src/polar/polar_setup.dart';

import 'polar_fixtures.dart';

void main() {
  // Memoriabeli fajlok: utvonal -> tartalom; a hianyzo fajl
  // FileSystemException, ahogy a valodi olvasasnal.
  Future<PolarSetup> load({
    String? polarPath = 'foretack.pol',
    String? correctionsPath,
    Map<String, String> files = const {'foretack.pol': flatPolarText},
  }) => loadPolarSetup(
    polarPath: polarPath,
    correctionsPath: correctionsPath,
    readBytes: (path) async {
      final content = files[path];
      if (content == null) throw FileSystemException('nincs meg', path);
      return utf8.encode(content);
    },
  );

  String fingerprintOf(PolarSetup setup) => switch (setup) {
    PolarReady(:final reference) => reference.fingerprint,
    PolarMissing(:final reason) => throw StateError('kesz polar kell: $reason'),
  };

  String reasonOf(PolarSetup setup) => switch (setup) {
    PolarReady() => throw StateError('hianyzo polart vartunk'),
    PolarMissing(:final reason) => reason,
  };

  group('loadPolarSetup', () {
    test('loads the polar without corrections', () async {
      // ACT
      final setup = await load();

      // ASSERT
      expect(setup, isA<PolarReady>());
      final reference = (setup as PolarReady).reference;
      expect(reference.corrections, isEmpty);
      expect(reference.polar.twsAxis, [4, 8, 12, 16, 20]);
      expect(reference.fingerprint, matches(r'^[0-9a-f]{16}$'));
    });

    test('loads the corrections and changes the fingerprint', () async {
      // ARRANGE
      const corrections =
          '[{"from": "2026-07-20T00:00:00+02:00", "factor": 1.081}]';

      // ACT
      final plain = await load();
      final corrected = await load(
        correctionsPath: 'stw.json',
        files: const {'foretack.pol': flatPolarText, 'stw.json': corrections},
      );

      // ASSERT
      expect((corrected as PolarReady).reference.corrections, hasLength(1));
      expect(fingerprintOf(corrected), isNot(fingerprintOf(plain)));
    });

    test('gives the same fingerprint for the same input', () async {
      expect(fingerprintOf(await load()), fingerprintOf(await load()));
    });

    test('is missing without the polar option', () async {
      expect(
        reasonOf(await load(polarPath: null)),
        'nincs --polar kapcsoló',
      );
    });

    test('is missing for an unreadable or malformed polar', () async {
      expect(
        reasonOf(await load(polarPath: 'nincs.pol')),
        startsWith('a polár nem olvasható'),
      );
      expect(
        reasonOf(await load(files: const {'foretack.pol': 'twa/tws\n'})),
        startsWith('a polár hibás'),
      );
    });

    test('does not fall back to no correction on a bad file', () async {
      // ACT
      final setup = await load(
        correctionsPath: 'stw.json',
        files: const {'foretack.pol': flatPolarText, 'stw.json': '{}'},
      );

      // ASSERT
      expect(reasonOf(setup), 'a korrekció-fájl hibás: JSON-tömb kell');
    });

    test('is missing for an unreadable corrections file', () async {
      expect(
        reasonOf(await load(correctionsPath: 'nincs.json')),
        startsWith('a korrekció-fájl nem olvasható'),
      );
    });
  });
}
