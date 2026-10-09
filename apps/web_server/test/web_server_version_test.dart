import 'dart:io';

import 'package:test/test.dart';
import 'package:web_server/src/web_server_version.dart';

void main() {
  test('matches the version in pubspec.yaml', () {
    // A dart test a package gyokerebol fut.
    final versionLine = File(
      'pubspec.yaml',
    ).readAsLinesSync().firstWhere((line) => line.startsWith('version:'));

    expect(versionLine.substring('version:'.length).trim(), webServerVersion);
  });
}
