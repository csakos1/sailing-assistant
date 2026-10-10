import 'dart:io';

import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/engine/gateway_probe.dart';

void main() {
  group('tcpGatewayProbe', () {
    test('a successful connection is found and closed at once', () async {
      // Arrange
      final connection = _FakeConnection();
      final calls = <String>[];
      final probe = tcpGatewayProbe(
        host: '192.168.76.1',
        timeout: const Duration(seconds: 3),
        connect: (host, port, {timeout = Duration.zero}) async {
          calls.add('$host:$port:${timeout.inSeconds}');
          return connection;
        },
      );

      // Act
      final isFound = await probe();

      // Assert
      expect(isFound, isTrue);
      expect(calls, ['192.168.76.1:10110:3']);
      expect(connection.isClosed, isTrue);
    });

    test('a refused or timed out connection is not found', () async {
      // Arrange
      final probe = tcpGatewayProbe(
        host: '192.168.76.1',
        timeout: const Duration(seconds: 3),
        connect: (host, port, {timeout = Duration.zero}) async =>
            throw const SocketException('Connection timed out'),
      );

      // Act
      final isFound = await probe();

      // Assert
      expect(isFound, isFalse);
    });

    test('an unexpected error is not found either', () async {
      // Arrange
      final probe = tcpGatewayProbe(
        host: '192.168.76.1',
        timeout: const Duration(seconds: 3),
        connect: (host, port, {timeout = Duration.zero}) async =>
            throw ArgumentError('bad host'),
      );

      // Act
      final isFound = await probe();

      // Assert
      expect(isFound, isFalse);
    });

    test('a failing close still counts as found', () async {
      // Arrange
      final probe = tcpGatewayProbe(
        host: '192.168.76.1',
        timeout: const Duration(seconds: 3),
        connect: (host, port, {timeout = Duration.zero}) async =>
            _FakeConnection(failOnClose: true),
      );

      // Act
      final isFound = await probe();

      // Assert
      expect(isFound, isTrue);
    });
  });
}

class _FakeConnection implements NmeaConnection {
  _FakeConnection({this.failOnClose = false});

  final bool failOnClose;
  bool isClosed = false;

  @override
  Stream<List<int>> get bytes => const Stream<List<int>>.empty();

  @override
  Future<void> close() async {
    isClosed = true;
    if (failOnClose) throw const SocketException('close failed');
  }
}
