import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/features/web_access/application/crew_overview.dart';
import 'package:phone/features/web_access/application/management_problem.dart';
import 'package:phone/features/web_access/application/web_access_error.dart';
import 'package:phone/features/web_access/application/web_access_providers.dart';
import 'package:phone/features/web_access/application/web_access_status_notifier.dart';
import 'package:phone/features/web_access/data/web_access_api_client.dart';
import 'package:phone/features/web_access/data/web_api_failure.dart';
import 'package:phone/features/web_access/data/web_key_operations.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';

/// A „Legénység" egy betöltése: az áttekintés, vagy a hiba (ADR 0051
/// Addendum 10 Z11).
typedef CrewLoad = Result<CrewOverview, WebAccessError>;

/// A „Legénység" képernyők adatai és műveletei (makett 18k–18k-4).
///
/// Csak amíg egy legénység-képernyő nyitva van (autoDispose). A hiba
/// adatként jön, mint a munkameneteknél. Egy sikeres művelet, vagy egy
/// közben már eldöntött kérelem (`410`) után a lista újratölt (Z3), és a
/// főképernyő szalagja is frissül, hogy a ⋮ menü jelvénye kövesse.
class CrewNotifier extends AutoDisposeAsyncNotifier<CrewLoad> {
  @override
  Future<CrewLoad> build() async {
    final calls = ref.watch(authorizedCallProvider);
    if (calls == null) return const Ok(CrewOverview.empty);
    final client = ref.watch(
      webAccessApiClientProvider(calls.tokens.account.origin),
    );
    // Egymás után: az eszköz-token forrása egyszerre egy tokent kér.
    final List<PendingJoinRequest> requests;
    switch (await calls.run(
      (token) => client.listJoinRequests(deviceToken: token),
    )) {
      case Ok(:final value):
        requests = value;
      case Err(:final error):
        return _failed(error);
    }
    final List<MemberInfo> members;
    switch (await calls.run(
      (token) => client.listMembers(deviceToken: token),
    )) {
      case Ok(:final value):
        members = value;
      case Err(:final error):
        return _failed(error);
    }
    final List<WebSession> sessions;
    switch (await calls.run(
      (token) => client.listSessions(deviceToken: token),
    )) {
      case Ok(:final value):
        sessions = value;
      case Err(:final error):
        return _failed(error);
    }
    return Ok(
      CrewOverview(requests: requests, members: members, sessions: sessions),
    );
  }

  /// A [request] jóváhagyása: új tagként, vagy a [memberId] tag új
  /// telefonjaként (M6); a [prompt] az ujjlenyomat-ablak (Z13). A hiba
  /// vagy `null`.
  Future<WebAccessError?> approve(
    PendingJoinRequest request, {
    required String? memberId,
    required BiometricPromptText prompt,
  }) => _signed(
    DeviceAction.approveJoin,
    target: joinApprovalTarget(joinRequestId: request.id, memberId: memberId),
    prompt: prompt,
    send: (client, action, token) => client.approveJoinRequest(
      request.id,
      JoinApproval(memberId: memberId, action: action),
      deviceToken: token,
    ),
  );

  /// A [joinRequestId] kérelem elutasítása, ujjlenyomat nélkül (K4). A
  /// hiba vagy `null`.
  Future<WebAccessError?> reject(String joinRequestId) async {
    final calls = ref.read(authorizedCallProvider);
    if (calls == null) return const ApiCallFailed(WebNetworkFailure('none'));
    final client = _clientFor(calls.tokens.account.origin);
    final status = ref.read(webAccessStatusProvider.notifier);
    final result = await calls.run(
      (token) => client.rejectJoinRequest(joinRequestId, deviceToken: token),
    );
    return _settle(result, status);
  }

  /// A [device] visszavonása (M7, H9: azonnal); a hiba vagy `null`.
  Future<WebAccessError?> revokeDevice(
    MemberDevice device, {
    required BiometricPromptText prompt,
  }) => _signed(
    DeviceAction.revokeDevice,
    target: device.id,
    prompt: prompt,
    send: (client, action, token) =>
        client.revokeDevice(device.id, action, deviceToken: token),
  );

  /// A [member] eltávolítása minden telefonjával és munkamenetével (M7);
  /// a hiba vagy `null`.
  Future<WebAccessError?> removeMember(
    MemberInfo member, {
    required BiometricPromptText prompt,
  }) => _signed(
    DeviceAction.removeUser,
    target: member.account.userId,
    prompt: prompt,
    send: (client, action, token) => client.removeMember(
      member.account.userId,
      action,
      deviceToken: token,
    ),
  );

  Future<WebAccessError?> _signed<T>(
    DeviceAction kind, {
    required String target,
    required BiometricPromptText prompt,
    required Future<Result<T, WebApiFailure>> Function(
      WebAccessApiClient client,
      SignedAction action,
      String token,
    )
    send,
  }) async {
    final runner = ref.read(signedActionRunnerProvider);
    if (runner == null) return const ApiCallFailed(WebNetworkFailure('none'));
    final client = _clientFor(runner.origin);
    final status = ref.read(webAccessStatusProvider.notifier);
    final result = await runner.signAndRun(
      kind,
      target: target,
      prompt: prompt,
      send: (action, token) => send(client, action, token),
    );
    return _settle(result, status);
  }

  // A siker és a „már nem érvényes" hiba után a lista újratölt (Z3), és a
  // szalag is frissül; a frissítést megvárjuk, hogy a művelet végén már
  // a friss jelvény álljon. A szalag notifierje a várakozás előtt van
  // elkapva: közben egy fiók-mentés (a `/me`) elavulttá teheti ezt a
  // providert, és akkor a `ref` már nem használható.
  Future<WebAccessError?> _settle<T>(
    Result<T, WebAccessError> result,
    WebAccessStatusNotifier status,
  ) async {
    switch (result) {
      case Ok():
        ref.invalidateSelf();
        await _refreshBanner(status);
        return null;
      case Err(:final error):
        final problem = managementProblemOf(error);
        if (problem is PhoneRevoked) status.markRevoked();
        if (problem is NoLongerValid) {
          ref.invalidateSelf();
          await _refreshBanner(status);
        }
        return error;
    }
  }

  // A szalag hibája (pl. egy fiók-írás) nem a művelet hibája: csak
  // naplózzuk, a művelet sikere áll.
  Future<void> _refreshBanner(WebAccessStatusNotifier status) async {
    try {
      await status.refreshAfterAction();
    } on Exception catch (exception) {
      debugPrint('web_access: $exception');
    }
  }

  CrewLoad _failed(WebAccessError error) {
    _markIfRevoked(error);
    return Err(error);
  }

  void _markIfRevoked(WebAccessError error) {
    if (managementProblemOf(error) is PhoneRevoked) {
      ref.read(webAccessStatusProvider.notifier).markRevoked();
    }
  }

  WebAccessApiClient _clientFor(String origin) =>
      ref.read(webAccessApiClientProvider(origin));
}
