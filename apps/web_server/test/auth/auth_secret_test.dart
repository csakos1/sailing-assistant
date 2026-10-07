import 'dart:io';

import 'package:shared/shared.dart';
import 'package:test/test.dart';
import 'package:web_server/src/auth/auth_secret.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('auth-secret-test');
  });

  tearDown(() => directory.delete(recursive: true));

  Future<File> secretFile(List<int> bytes, {required String mode}) async {
    final file = File('${directory.path}/auth-secret');
    await file.writeAsBytes(bytes);
    final result = await Process.run('chmod', [mode, file.path]);
    expect(result.exitCode, 0, reason: '${result.stderr}');
    return file;
  }

  AuthSecret loaded(Result<AuthSecret, AuthSecretError> result) =>
      switch (result) {
        Ok(:final value) => value,
        Err(:final error) => throw StateError('Ok-t vartunk: $error'),
      };

  Future<AuthSecret> secretOf(List<int> bytes) async =>
      loaded(await loadAuthSecret(await secretFile(bytes, mode: '600')));

  group('loadAuthSecret', () {
    test('loads a 0600 file of at least 32 bytes', () async {
      final file = await secretFile(List.filled(32, 7), mode: '600');

      final secret = loaded(await loadAuthSecret(file));

      expect(secret.toString(), isNot(contains('7')));
    });

    test('refuses a file the group can read', () async {
      final file = await secretFile(List.filled(32, 7), mode: '640');

      expect(
        await loadAuthSecret(file),
        const Err<AuthSecret, AuthSecretError>(AuthSecretError.tooPermissive),
      );
    });

    test('refuses a file shorter than 32 bytes', () async {
      final file = await secretFile(List.filled(31, 7), mode: '600');

      expect(
        await loadAuthSecret(file),
        const Err<AuthSecret, AuthSecretError>(AuthSecretError.tooShort),
      );
    });

    test('reports a missing file or a directory as unreadable', () async {
      const unreadable = Err<AuthSecret, AuthSecretError>(
        AuthSecretError.unreadable,
      );

      final missing = File('${directory.path}/nincs');

      expect(await loadAuthSecret(missing), unreadable);
      expect(await loadAuthSecret(File(directory.path)), unreadable);
    });
  });

  group('AuthSecret.digestRecoveryCode', () {
    test('is stable per code and differs by code and by secret', () async {
      final first = await secretOf(List.filled(32, 1));
      final second = await secretOf(List.filled(32, 2));

      expect(
        first.digestRecoveryCode('K7Q2M7XWPD'),
        first.digestRecoveryCode('K7Q2M7XWPD'),
      );
      expect(
        first.digestRecoveryCode('K7Q2M7XWPD'),
        isNot(first.digestRecoveryCode('K7Q2M7XWPE')),
      );
      expect(
        first.digestRecoveryCode('K7Q2M7XWPD'),
        isNot(second.digestRecoveryCode('K7Q2M7XWPD')),
      );
    });

    test('matches HMAC-SHA-256 with the domain prefix', () async {
      final secret = await secretOf(List.filled(32, 1));

      // Pythonnal: hmac.new(bytes([1]*32),
      //   b'foretack-recovery-v1\nK7Q2M7XWPD', 'sha256').hexdigest()
      expect(
        secret.digestRecoveryCode('K7Q2M7XWPD'),
        _hex(_recoveryDigestHex),
      );
    });
  });
}

const String _recoveryDigestHex =
    '872652f8d5b5a9404c4e4016546cf3be800165b3112ad85ac6d0f9f4ff200695';

List<int> _hex(String hex) => [
  for (var i = 0; i < hex.length; i += 2)
    int.parse(hex.substring(i, i + 2), radix: 16),
];
