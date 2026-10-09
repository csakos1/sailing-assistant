import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/features/web_access/application/management_problem.dart';
import 'package:phone/features/web_access/application/web_access_error.dart';
import 'package:phone/features/web_access/application/web_access_providers.dart';
import 'package:phone/features/web_access/application/web_access_status_notifier.dart';
import 'package:phone/features/web_access/data/web_api_failure.dart';
import 'package:phone/features/web_access/data/web_key_operations.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';

/// A tartalék belépés állapotának egy betöltése: a `crew`-nál `null`
/// (nincs tartaléka, D6), különben az állapot vagy a hiba (ADR 0051
/// Addendum 10 Z11).
typedef AccountSecurityLoad = Result<AccountSecurity?, WebAccessError>;

/// A „Fiók és biztonság" jelszó- és kódrésze (makett 18l, 18l-3).
///
/// Csak amíg a képernyő nyitva van (autoDispose). Egy sikeres művelet után
/// az állapot újratölt („Beállítva: …", „Felhasználatlan N / 10").
class AccountSecurityNotifier
    extends AutoDisposeAsyncNotifier<AccountSecurityLoad> {
  @override
  Future<AccountSecurityLoad> build() async {
    final calls = ref.watch(authorizedCallProvider);
    if (calls == null) return const Ok(null);
    if (calls.tokens.account.account.role != UserRole.owner) {
      return const Ok(null);
    }
    final client = ref.watch(
      webAccessApiClientProvider(calls.tokens.account.origin),
    );
    final loaded = await calls.run(
      (token) => client.fetchAccountSecurity(deviceToken: token),
    );
    switch (loaded) {
      case Ok(:final value):
        return Ok(value);
      case Err(:final error):
        if (managementProblemOf(error) is PhoneRevoked) {
          ref.read(webAccessStatusProvider.notifier).markRevoked();
        }
        return Err(error);
    }
  }

  /// Új tartalék-jelszó (N4); a [password]-öt a hívó már ellenőrizte
  /// (`isAcceptablePassword`), a [prompt] az ujjlenyomat-ablak (Z13). A
  /// hiba vagy `null`.
  Future<WebAccessError?> setPassword(
    String password, {
    required BiometricPromptText prompt,
  }) async {
    final runner = ref.read(signedActionRunnerProvider);
    if (runner == null) return const ApiCallFailed(WebNetworkFailure('none'));
    final client = ref.read(webAccessApiClientProvider(runner.origin));
    final status = ref.read(webAccessStatusProvider.notifier);
    final result = await runner.signAndRun(
      DeviceAction.setPassword,
      target: '-',
      prompt: prompt,
      send: (action, token) => client.setPassword(
        PasswordChange(password: password, action: action),
        deviceToken: token,
      ),
    );
    return switch (_settle(result, status)) {
      Ok() => null,
      Err(:final error) => error,
    };
  }

  /// Tíz új helyreállító kód (N4, 18l-3); a régiek azonnal érvénytelenek.
  Future<Result<List<String>, WebAccessError>> regenerateRecoveryCodes({
    required BiometricPromptText prompt,
  }) async {
    final runner = ref.read(signedActionRunnerProvider);
    if (runner == null) {
      return const Err(ApiCallFailed(WebNetworkFailure('none')));
    }
    final client = ref.read(webAccessApiClientProvider(runner.origin));
    final status = ref.read(webAccessStatusProvider.notifier);
    final result = await runner.signAndRun(
      DeviceAction.regenerateRecoveryCodes,
      target: '-',
      prompt: prompt,
      send: (action, token) =>
          client.regenerateRecoveryCodes(action, deviceToken: token),
    );
    return switch (_settle(result, status)) {
      Ok(:final value) => Ok(value.codes),
      Err(:final error) => Err(error),
    };
  }

  // A szalag notifierje a várakozás előtt van elkapva: közben egy
  // fiók-mentés (a `/me`) elavulttá teheti ezt a providert, és akkor a
  // `ref.read` már nem használható.
  Result<T, WebAccessError> _settle<T>(
    Result<T, WebAccessError> result,
    WebAccessStatusNotifier status,
  ) {
    switch (result) {
      case Ok():
        ref.invalidateSelf();
      case Err(:final error):
        if (managementProblemOf(error) is PhoneRevoked) status.markRevoked();
    }
    return result;
  }
}
