import 'dart:typed_data';

import 'package:phone/features/web_access/application/authorized_call.dart';
import 'package:phone/features/web_access/application/web_access_error.dart';
import 'package:phone/features/web_access/data/web_access_api_client.dart';
import 'package:phone/features/web_access/data/web_api_failure.dart';
import 'package:phone/features/web_access/data/web_key_operations.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';

/// Egy ujjlenyomatos művelet aláírása (ADR 0051 Addendum 5 M2, Addendum
/// 10 Z3).
///
/// Eszköz-token → akció-kihívás → `foretack-action-v1` az aláíró kulccsal.
/// Az eredmény a művelet törzsébe kerülő `SignedAction`. A kihívás
/// egyszeri, ezért egy elbukott műveletet a hívó nem próbál újra ugyanazzal.
class SignedActionRunner {
  /// Aláíró a [_client] szerverén, a [_calls] tokenjeivel és a
  /// [_signWithBiometrics] aláíróval.
  SignedActionRunner({
    required WebAccessApiClient client,
    required AuthorizedCall calls,
    required SignWithBiometrics signWithBiometrics,
  }) : _client = client,
       _calls = calls,
       _signWithBiometrics = signWithBiometrics;

  final WebAccessApiClient _client;
  final AuthorizedCall _calls;
  final SignWithBiometrics _signWithBiometrics;

  /// A szerver origója, amelynek a műveleteit aláírja.
  String get origin => _calls.tokens.account.origin;

  /// A [kind] művelet aláírása a [target] céllal; a [prompt] az
  /// ujjlenyomat-ablak szövege (Z13).
  Future<Result<SignedAction, WebAccessError>> sign(
    DeviceAction kind, {
    required String target,
    required BiometricPromptText prompt,
  }) async {
    final String challenge;
    switch (await _calls.run(
      (token) => _client.issueActionChallenge(deviceToken: token),
    )) {
      case Ok(:final value):
        challenge = value.value;
      case Err(:final error):
        return Err(error);
    }
    final account = _calls.tokens.account;
    final message = deviceActionMessage(
      origin: account.origin,
      deviceId: account.deviceId,
      challenge: challenge,
      action: kind,
      target: target,
    );
    final Uint8List signature;
    switch (await _signWithBiometrics(message, prompt)) {
      case Ok(:final value):
        signature = value;
      case Err(:final error):
        return Err(KeyOperationFailed(error));
    }
    return Ok(SignedAction(challenge: challenge, signature: signature));
  }

  /// A [kind] művelet aláírása ([sign]), utána a [send] kérés az aláírással
  /// és egy eszköz-tokennel.
  ///
  /// Egy `401` utáni újrapróba ugyanazt az aláírást küldi: a szerver a
  /// tokent a kihívás elhasználása előtt nézi (M2), így az még érvényes.
  Future<Result<T, WebAccessError>> signAndRun<T>(
    DeviceAction kind, {
    required String target,
    required BiometricPromptText prompt,
    required Future<Result<T, WebApiFailure>> Function(
      SignedAction action,
      String deviceToken,
    )
    send,
  }) async {
    switch (await sign(kind, target: target, prompt: prompt)) {
      case Ok(value: final action):
        return _calls.run((token) => send(action, token));
      case Err(:final error):
        return Err(error);
    }
  }
}
