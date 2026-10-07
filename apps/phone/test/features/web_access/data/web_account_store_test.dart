import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:phone/features/web_access/data/file_web_account_store.dart';
import 'package:phone/features/web_access/data/web_account_codec.dart';
import 'package:race_archive_api/race_archive_api.dart';

import '../web_access_fakes.dart';

void main() {
  late Directory directory;
  late FileWebAccountStore store;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('web_account_test');
    store = FileWebAccountStore(() async => directory);
  });

  tearDown(() => directory.deleteSync(recursive: true));

  File accountFile() => File('${directory.path}/$webAccountFileName');

  group('FileWebAccountStore', () {
    test('a missing file means no account', () async {
      // Act
      final account = await store.read();

      // Assert
      expect(account, isNull);
    });

    test('a written account reads back unchanged', () async {
      // Arrange
      final account = testAccount(role: UserRole.crew);

      // Act
      await store.write(account);
      final read = await store.read();

      // Assert
      expect(read, account);
      expect(File('${accountFile().path}.tmp').existsSync(), isFalse);
    });

    test('a corrupt file means no account instead of a crash', () async {
      // Arrange
      accountFile().writeAsStringSync('{"version": 1, "origin": ');

      // Act
      final account = await store.read();

      // Assert
      expect(account, isNull);
    });

    test('bytes that are not UTF-8 mean no account', () async {
      // Arrange
      accountFile().writeAsBytesSync([0xFF, 0xFE, 0x00]);

      // Act
      final account = await store.read();

      // Assert
      expect(account, isNull);
    });

    test('delete removes only the account file', () async {
      // Arrange
      final unrelated = File('${directory.path}/foretack.sqlite')
        ..writeAsStringSync('races');
      await store.write(testAccount());

      // Act
      await store.delete();
      await store.delete();

      // Assert
      expect(accountFile().existsSync(), isFalse);
      expect(unrelated.readAsStringSync(), 'races');
    });
  });

  group('decodeWebAccount', () {
    test('round-trips through the encoder', () {
      // Arrange
      final account = testAccount();

      // Act
      final decoded = decodeWebAccount(encodeWebAccount(account));

      // Assert
      expect(decoded, account);
    });

    test('rejects an unknown version, role or a non-canonical origin', () {
      // Arrange
      final valid = encodeWebAccount(testAccount());

      // Act and assert
      expect(decodeWebAccount({...valid, 'version': 2}), isNull);
      expect(decodeWebAccount({...valid, 'role': 'admin'}), isNull);
      expect(
        decodeWebAccount({...valid, 'origin': 'http://localhost:8080/'}),
        isNull,
      );
      expect(decodeWebAccount({...valid, 'deviceId': ''}), isNull);
      expect(decodeWebAccount('not an object'), isNull);
    });
  });
}
