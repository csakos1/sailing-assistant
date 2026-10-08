import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:phone/features/web_access/data/file_web_account_store.dart';
import 'package:phone/features/web_access/data/pending_join_codec.dart';
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

  group('pending join in the same file', () {
    test('a written pending join reads back, and is not an account', () async {
      // Arrange
      final pending = testPendingJoin();

      // Act
      await store.writePendingJoin(pending);

      // Assert
      expect(await store.readPendingJoin(), pending);
      expect(await store.read(), isNull);
    });

    test('an account replaces the pending join, and back', () async {
      // Arrange
      await store.writePendingJoin(testPendingJoin());

      // Act
      await store.write(testAccount());

      // Assert
      expect(await store.readPendingJoin(), isNull);
      expect(await store.read(), testAccount());

      // Act
      await store.writePendingJoin(testPendingJoin());

      // Assert
      expect(await store.read(), isNull);
    });

    test('a file with both an account and a pending join is neither', () {
      // Arrange
      final both = {
        ...encodeWebAccount(testAccount()),
        ...encodePendingJoinFile(testPendingJoin()),
      };

      // Act and assert
      expect(decodeWebAccount(both), isNull);
      expect(decodePendingJoinFile(both), isNull);
    });

    test('the status token stays out of the description', () {
      // Act
      final description = testPendingJoin().toString();

      // Assert
      expect(description, isNot(contains(testStatusToken)));
    });
  });

  group('decodePendingJoinFile', () {
    test('round-trips through the encoder in UTC', () {
      // Arrange
      final pending = testPendingJoin();

      // Act
      final decoded = decodePendingJoinFile(encodePendingJoinFile(pending));

      // Assert
      expect(decoded, pending);
      expect(decoded?.expiresAt.isUtc, isTrue);
    });

    test('rejects a missing field, a bad origin or a wrong version', () {
      // Arrange
      final valid = encodePendingJoinFile(testPendingJoin());
      final inner = valid[pendingJoinKey]! as Map<String, Object?>;
      Map<String, Object?> withInner(Map<String, Object?> changed) => {
        ...valid,
        pendingJoinKey: {...inner, ...changed},
      };

      // Act and assert
      expect(decodePendingJoinFile({...valid, 'version': 2}), isNull);
      expect(decodePendingJoinFile(withInner({'statusToken': ''})), isNull);
      expect(decodePendingJoinFile(withInner({'expiresAt': '1'})), isNull);
      expect(
        decodePendingJoinFile(withInner({'origin': 'localhost:8080'})),
        isNull,
      );
      expect(decodePendingJoinFile(encodeWebAccount(testAccount())), isNull);
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
