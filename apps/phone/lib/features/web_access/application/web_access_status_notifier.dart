import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/features/web_access/application/authorized_call.dart';
import 'package:phone/features/web_access/application/management_problem.dart';
import 'package:phone/features/web_access/application/web_access_error.dart';
import 'package:phone/features/web_access/application/web_access_providers.dart';
import 'package:phone/features/web_access/application/web_access_status.dart';
import 'package:phone/features/web_access/data/web_access_api_client.dart';
import 'package:phone/features/web_access/data/web_account.dart';
import 'package:phone/features/web_access/data/web_api_failure.dart';
import 'package:shared/shared.dart';

/// A szalag, a visszavont jelzés és a fiók frissítése (ADR 0051 Addendum
/// 10 Z4, Z5, Z7).
///
/// A [refresh] a szalagot és a `/me`-t kéri le; ugyanarra a fiókra
/// egyszerre egy fut, a többi hívó ugyanazt várja. A visszavont jelzés
/// egy új fiókig megmarad: egy közben jött hálózati hiba nem törli. Egy
/// másik fiókra váltáskor (regisztráció, csatlakozás, csere) az állapot
/// üres lesz.
class WebAccessStatusNotifier extends Notifier<WebAccessStatus> {
  Future<void>? _running;
  (String, String)? _runningFor;

  @override
  WebAccessStatus build() {
    ref.listen(webAccountProvider, (previous, next) {
      if (_identityOf(previous?.valueOrNull) != _identityOf(next.valueOrNull)) {
        _running = null;
        _runningFor = null;
        state = WebAccessStatus.none;
      }
    });
    return WebAccessStatus.none;
  }

  /// A szalag és a fiók frissítése; ugyanarra a fiókra egy már futó
  /// frissítést nem indít újra.
  Future<void> refresh() {
    final account = _identityOf(ref.read(webAccountProvider).valueOrNull);
    final running = _running;
    if (running != null && _runningFor == account) return running;
    return _start(account);
  }

  /// Új frissítés egy másik képernyő művelete után (Z5), akkor is, ha egy
  /// korábbi még fut: az a művelet előtti szalagot és jelvényt hozná.
  Future<void> refreshAfterAction() =>
      _start(_identityOf(ref.read(webAccountProvider).valueOrNull));

  /// A telefon visszavont állapotba kerül (egy képernyő hívása `403`-at
  /// kapott, Z4).
  void markRevoked() => state = WebAccessStatus.revoked;

  /// Egy gyanús belépés nyugtázása („Rendben", H8); a hiba vagy `null`.
  Future<WebAccessError?> acknowledge(String eventId) => _act(
    (client, token) =>
        client.acknowledgeLoginEvent(eventId, deviceToken: token),
  );

  /// Egy munkamenet kiléptetése (a szalagról és a 18i-ből, H8, H9); a
  /// szerver a gyanús eseményét is nyugtázza (N6). A hiba vagy `null`.
  Future<WebAccessError?> endSession(String sessionId) => _act(
    (client, token) => client.endSession(sessionId, deviceToken: token),
  );

  Future<void> _start((String, String)? account) {
    _runningFor = account;
    late final Future<void> started;
    started = _refresh().whenComplete(() {
      // Egy közben indult újabb frissítés a sajátját tartja meg.
      if (identical(_running, started)) {
        _running = null;
        _runningFor = null;
      }
    });
    return _running = started;
  }

  Future<WebAccessError?> _act(
    Future<Result<void, WebApiFailure>> Function(
      WebAccessApiClient client,
      String token,
    )
    send,
  ) async {
    final calls = ref.read(authorizedCallProvider);
    if (calls == null) return const ApiCallFailed(WebNetworkFailure('none'));
    final client = _clientOf(calls);
    switch (await calls.run((token) => send(client, token))) {
      case Ok():
        // Egy a művelet előtt indult frissítés még a régi szalagot hozná.
        await _start(_identityOf(calls.tokens.account));
        return null;
      case Err(:final error):
        if (managementProblemOf(error) is PhoneRevoked) markRevoked();
        return error;
    }
  }

  Future<void> _refresh() async {
    final calls = ref.read(authorizedCallProvider);
    if (calls == null) {
      state = WebAccessStatus.none;
      return;
    }
    final account = calls.tokens.account;
    final client = _clientOf(calls);
    final banner = await calls.run(
      (token) => client.fetchBanner(deviceToken: token),
    );
    if (!_isCurrent(account) || state.isRevoked) return;
    switch (banner) {
      case Ok(:final value):
        state = WebAccessStatus(banner: value);
      case Err(:final error):
        _onRefreshError(error, keepBanner: false);
        return;
    }
    final me = await calls.run(
      (token) => client.fetchAccount(deviceToken: token),
    );
    if (!_isCurrent(account)) return;
    switch (me) {
      case Ok(:final value) when value != account.account:
        // Az origó és az eszköz marad: csak a név vagy a szerep változott.
        await ref
            .read(webAccountProvider.notifier)
            .save(
              WebAccount(
                origin: account.origin,
                account: value,
                deviceId: account.deviceId,
              ),
            );
      case Ok():
        break;
      case Err(:final error):
        _onRefreshError(error, keepBanner: true);
    }
  }

  // A visszavont telefon jelzést kap (Z4); más hibánál a szalag eltűnik
  // (H11), hacsak csak a `/me` bukott el egy friss szalag után.
  void _onRefreshError(WebAccessError error, {required bool keepBanner}) {
    debugPrint('web_access: $error');
    if (managementProblemOf(error) is PhoneRevoked) {
      state = WebAccessStatus.revoked;
    } else if (!keepBanner && !state.isRevoked) {
      state = WebAccessStatus.none;
    }
  }

  // Egy közben lecserélt fiók régi válasza nem írhatja felül az újat.
  bool _isCurrent(WebAccount account) =>
      _identityOf(ref.read(webAccountProvider).valueOrNull) ==
      _identityOf(account);

  WebAccessApiClient _clientOf(AuthorizedCall calls) =>
      ref.read(webAccessApiClientProvider(calls.tokens.account.origin));
}

(String, String)? _identityOf(WebAccount? account) =>
    account == null ? null : (account.origin, account.deviceId);
