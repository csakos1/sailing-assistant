import 'package:flutter_test/flutter_test.dart';
import 'package:phone/features/web_access/application/join_outcome.dart';
import 'package:phone/features/web_access/application/join_status_check.dart';
import 'package:phone/features/web_access/data/web_access_api_client.dart';
import 'package:race_archive_api/race_archive_api.dart';

import '../web_access_fakes.dart';

void main() {
  late FakeWebServer server;
  late FakeKeys keys;
  late MemoryWebAccountStore store;
  late DateTime now;
  late JoinStatusCheck check;

  setUp(() {
    server = FakeWebServer();
    keys = FakeKeys();
    store = MemoryWebAccountStore()..pendingJoin = testPendingJoin();
    now = testNow;
    check = JoinStatusCheck(
      clientFor: (origin) => WebAccessApiClient(server.client, origin: origin),
      saveAccount: store.write,
      clearPendingJoin: store.delete,
      deleteKeys: keys.operations.deleteKeys,
      now: () => now,
    );
  });

  void answer(JoinRequestState state) =>
      server.routes[joinRequestStatusPath(testJoinRequestId)] = (_) =>
          joinStatusResponse(state);

  test('an undecided request changes nothing', () async {
    // Arrange
    answer(JoinRequestState.pending);

    // Act
    final outcome = await check.run(testPendingJoin());

    // Assert
    expect(outcome, isA<JoinStillPending>());
    expect(store.pendingJoin, testPendingJoin());
    expect(keys.calls, isEmpty);
  });

  test('an approval saves the account and keeps the keys', () async {
    // Arrange
    answer(JoinRequestState.approved);

    // Act
    final outcome = await check.run(testPendingJoin());

    // Assert
    final account = (outcome as JoinApproved).account;
    expect(account.origin, testOrigin);
    expect(account.deviceId, 'device-7');
    expect(account.account.role, UserRole.crew);
    expect(store.account, account);
    expect(store.pendingJoin, isNull);
    expect(keys.calls, isEmpty);
  });

  test('a refusal drops the request and the keys', () async {
    // Arrange
    answer(JoinRequestState.notApproved);

    // Act
    final outcome = await check.run(testPendingJoin());

    // Assert
    expect(outcome, isA<JoinNotApproved>());
    expect(store.pendingJoin, isNull);
    expect(store.account, isNull);
    expect(keys.calls, ['delete']);
  });

  test('an expired request is dropped without asking the server', () async {
    // Arrange
    now = testPendingJoin().expiresAt;

    // Act
    final outcome = await check.run(testPendingJoin());

    // Assert
    expect(outcome, isA<JoinNotApproved>());
    expect(server.requests, isEmpty);
    expect(store.pendingJoin, isNull);
    expect(keys.calls, ['delete']);
  });

  test('an unreadable answer keeps everything for the next try', () async {
    // Arrange: no route, the fake server answers 404 without a JSON body

    // Act
    final outcome = await check.run(testPendingJoin());

    // Assert
    expect(outcome, isA<JoinCheckFailed>());
    expect(store.pendingJoin, testPendingJoin());
    expect(keys.calls, isEmpty);
  });

  test('expiry is decided by the phone clock to the millisecond', () {
    // Arrange
    final expiresAt = testPendingJoin().expiresAt;

    // Act
    now = expiresAt.subtract(const Duration(milliseconds: 1));
    final isLiveJustBefore = !check.isExpired(testPendingJoin());
    now = expiresAt;
    final isExpiredAtTheEnd = check.isExpired(testPendingJoin());

    // Assert
    expect(isLiveJustBefore, isTrue);
    expect(isExpiredAtTheEnd, isTrue);
  });
}
