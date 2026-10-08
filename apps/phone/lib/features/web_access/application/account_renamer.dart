import 'package:phone/features/web_access/application/authorized_call.dart';
import 'package:phone/features/web_access/application/web_access_error.dart';
import 'package:phone/features/web_access/data/web_access_api_client.dart';
import 'package:phone/features/web_access/data/web_account.dart';
import 'package:shared/shared.dart';

/// A fiók mentése a fiók-tárba (a `WebAccountNotifier.save`).
typedef SaveWebAccount = Future<void> Function(WebAccount account);

/// A saját név átírása (ADR 0051 Addendum 5 M9, Addendum 10 Z11).
///
/// Ujjlenyomat nélkül, eszköz-tokennel (K4). Siker után a fiók-fájl is az
/// új nevet hordja (V3), hogy a főképernyő és a „Webes belépések" csoportja
/// a `/me` megvárása nélkül is az újat mutassa.
///
/// Nem a képernyő notifierje csinálja: a fiók mentése a webes providereket
/// újraépíti, és egy épp újraépülő provider `ref`-je a mentés után már nem
/// használható.
class AccountRenamer {
  /// Átnevező a [calls] tokenjeivel, a [client] szerverén.
  AccountRenamer({
    required AuthorizedCall calls,
    required WebAccessApiClient client,
    required SaveWebAccount saveAccount,
  }) : _calls = calls,
       _client = client,
       _saveAccount = saveAccount;

  final AuthorizedCall _calls;
  final WebAccessApiClient _client;
  final SaveWebAccount _saveAccount;

  /// A név átírása a [name]-re (a hívó már a `normalizeDisplayName`
  /// alakját adja); a hiba vagy `null`.
  Future<WebAccessError?> call(String name) async {
    final current = _calls.tokens.account;
    final result = await _calls.run(
      (token) => _client.renameAccount(name, deviceToken: token),
    );
    switch (result) {
      case Ok(:final value):
        await _saveAccount(
          WebAccount(
            origin: current.origin,
            account: value,
            deviceId: current.deviceId,
          ),
        );
        return null;
      case Err(:final error):
        return error;
    }
  }
}
