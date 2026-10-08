import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:phone/features/web_access/application/crew_notifier.dart';
import 'package:phone/features/web_access/application/management_problem.dart';
import 'package:phone/features/web_access/application/web_access_error.dart';
import 'package:phone/features/web_access/application/web_access_providers.dart';
import 'package:phone/features/web_access/data/web_key_operations.dart';
import 'package:phone/providers/clock_provider.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';

import '../web_access_fakes.dart';

void main() {
  late FakeWebServer server;
  late FakeKeys keys;
  late MemoryWebAccountStore store;
  late ProviderContainer container;

  const prompt = BiometricPromptText(title: 'Teszt', cancel: 'Mégse');
  final request = testPendingRequest();
  final dori = testMember(
    userId: 'u-dori',
    name: 'Dóri',
    role: UserRole.crew,
    devices: [testMemberDevice()],
  );

  setUp(() {
    server = FakeWebServer();
    keys = FakeKeys();
    store = MemoryWebAccountStore(testAccount());
    serveDeviceTokens(server);
    serveActionChallenges(server);
    server.routes[joinRequestsPath] = (_) => joinRequestsResponse([request]);
    server.routes[membersPath] = (_) => membersResponse([testMember(), dori]);
    server.routes[sessionsPath] = (_) => sessionsResponse([testSession()]);
    server.routes[bannerPath] = (_) => bannerResponse();
    server.routes[mePath] = (_) => meResponse();
    container = ProviderContainer(
      overrides: [
        webAccountStoreProvider.overrideWithValue(store),
        pendingJoinStoreProvider.overrideWithValue(store),
        webHttpClientProvider.overrideWithValue(server.client),
        webKeyOperationsProvider.overrideWithValue(keys.operations),
        clockProvider.overrideWithValue(() => testNow),
      ],
    );
    addTearDown(container.dispose);
    // Az autoDispose provider csak figyelve marad eletben.
    container.listen(crewProvider, (_, _) {});
  });

  Future<CrewLoad> load() async {
    await container.read(webAccountProvider.future);
    return container.read(crewProvider.future);
  }

  CrewNotifier notifier() => container.read(crewProvider.notifier);

  // Az utolso ujjlenyomatos alairas uzenetenek sorai.
  List<String> signedLines() =>
      const LineSplitter().convert(utf8.decode(keys.signedMessages.last));

  int requestsTo(String path) => server.requestsTo(path).length;

  group('loading', () {
    test('brings the requests, the members and the sessions', () async {
      // Act
      final loaded = await load();

      // Assert
      final overview = switch (loaded) {
        Ok(:final value) => value,
        Err() => null,
      };
      expect(overview?.requests, [request]);
      expect(overview?.members, [testMember(), dori]);
      expect(overview?.sessions, [testSession()]);
    });

    test('a failed list is the error of the load', () async {
      // Arrange
      server.routes[membersPath] = (_) => http.Response('down', 502);

      // Act
      final loaded = await load();

      // Assert
      expect(loaded, isA<Err<Object?, Object?>>());
      expect(requestsTo(sessionsPath), 0);
    });

    test('a revoked phone marks the home screen as revoked', () async {
      // Arrange
      server.routes[deviceChallengesPath] = (_) =>
          errorResponse(const DeviceRevoked());

      // Act
      await load();

      // Assert
      expect(container.read(webAccessStatusProvider).isRevoked, isTrue);
    });
  });

  group('decisions', () {
    test('approving a new member signs the new-member target', () async {
      // Arrange
      final path = joinRequestApprovalPath(request.id);
      server.routes[path] = (_) => jsonResponse(encodeMemberInfo(dori));
      await load();

      // Act
      final error = await notifier().approve(
        request,
        memberId: null,
        prompt: prompt,
      );
      await container.read(crewProvider.future);

      // Assert
      expect(error, isNull);
      expect(signedLines().last, '${request.id}:new');
      expect(signedLines(), contains('approveJoin'));
      expect(FakeWebServer.bodyOf(server.requestsTo(path).single), {
        'memberId': null,
        'challenge': testChallenge,
        'signature': base64Encode(FakeKeys.biometricSignature),
      });
      // A lista ujratolt, a szalag frissul.
      expect(requestsTo(joinRequestsPath), 2);
      expect(requestsTo(bannerPath), greaterThan(0));
    });

    test("approving as a member's phone carries the member", () async {
      // Arrange
      final path = joinRequestApprovalPath(request.id);
      server.routes[path] = (_) => jsonResponse(encodeMemberInfo(dori));
      await load();

      // Act
      await notifier().approve(request, memberId: 'u-dori', prompt: prompt);

      // Assert
      expect(signedLines().last, '${request.id}:u-dori');
      expect(
        FakeWebServer.bodyOf(server.requestsTo(path).single)['memberId'],
        'u-dori',
      );
    });

    test('a cancelled fingerprint sends nothing and stays quiet', () async {
      // Arrange
      keys.biometricFailure = KeyOperationFailure.canceled;
      await load();

      // Act
      final error = await notifier().approve(
        request,
        memberId: null,
        prompt: prompt,
      );

      // Assert
      expect(error, isA<KeyOperationFailed>());
      expect(error == null ? 'none' : managementProblemOf(error), isNull);
      expect(requestsTo(joinRequestApprovalPath(request.id)), 0);
      expect(requestsTo(joinRequestsPath), 1);
    });

    test('a request decided elsewhere reloads the list', () async {
      // Arrange
      server.routes[joinRequestApprovalPath(request.id)] = (_) =>
          errorResponse(const RequestExpired());
      await load();

      // Act
      final error = await notifier().approve(
        request,
        memberId: null,
        prompt: prompt,
      );
      await container.read(crewProvider.future);

      // Assert
      expect(
        error == null ? null : managementProblemOf(error),
        isA<NoLongerValid>(),
      );
      expect(requestsTo(joinRequestsPath), 2);
    });

    test('rejecting needs no fingerprint', () async {
      // Arrange
      final path = joinRequestRejectionPath(request.id);
      server.routes[path] = (_) => http.Response('', 204);
      await load();

      // Act
      final error = await notifier().reject(request.id);

      // Assert
      expect(error, isNull);
      expect(server.requestsTo(path).single.body, isEmpty);
      expect(keys.calls, isNot(contains('sign:biometric')));
    });
  });

  group('members', () {
    test('revoking a phone signs its id', () async {
      // Arrange
      final device = testMemberDevice();
      final path = deviceRevocationPath(device.id);
      server.routes[path] = (_) => http.Response('', 204);
      await load();

      // Act
      final error = await notifier().revokeDevice(device, prompt: prompt);

      // Assert
      expect(error, isNull);
      expect(signedLines(), contains('revokeDevice'));
      expect(signedLines().last, device.id);
      expect(server.requestsTo(path), hasLength(1));
    });

    test('removing a member signs the user id', () async {
      // Arrange
      final path = memberRemovalPath('u-dori');
      server.routes[path] = (_) => http.Response('', 204);
      await load();

      // Act
      final error = await notifier().removeMember(dori, prompt: prompt);

      // Assert
      expect(error, isNull);
      expect(signedLines(), contains('removeUser'));
      expect(signedLines().last, 'u-dori');
      expect(keys.prompts.single.title, 'Teszt');
    });
  });
}
