import 'dart:typed_data';

import 'package:phone/features/web_access/application/device_token_source.dart';
import 'package:phone/features/web_access/application/web_access_error.dart';
import 'package:phone/features/web_access/data/web_access_api_client.dart';
import 'package:phone/features/web_access/data/web_api_failure.dart';
import 'package:phone/features/web_access/data/web_key_operations.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';

/// Az ujjlenyomat-ablak szövegei a kérő böngésző adataiból (H6).
typedef LoginPromptOf = BiometricPromptText Function(BrowserLoginDetails);

/// A QR-belépés a telefonon (ADR 0051 D4, Addendum 8 V6).
///
/// Eszköz-token → a kérés megnyitása → ujjlenyomatos aláírás →
/// jóváhagyás. A sikeres eredmény a kérő böngésző adatai, a snackbarhoz
/// (18d).
class QrLoginFlow {
  /// Folyamat a [_client] szerverén, a [_tokens] eszköz-tokenjeivel és a
  /// [_signWithBiometrics] aláíróval.
  QrLoginFlow({
    required WebAccessApiClient client,
    required DeviceTokenSource tokens,
    required SignWithBiometrics signWithBiometrics,
  }) : _client = client,
       _tokens = tokens,
       _signWithBiometrics = signWithBiometrics;

  final WebAccessApiClient _client;
  final DeviceTokenSource _tokens;
  final SignWithBiometrics _signWithBiometrics;

  /// Belépés a [payload] kéréssel; a [promptOf] adja az ujjlenyomat-ablak
  /// szövegeit. A [payload] origója a fiók origója (a hívó útválasztása
  /// ezt már ellenőrizte, V5).
  Future<Result<BrowserLoginDetails, WebAccessError>> run(
    LoginQrPayload payload, {
    required LoginPromptOf promptOf,
  }) async {
    final BrowserLoginDetails details;
    switch (await _open(payload)) {
      case Ok(:final value):
        details = value;
      case Err(:final error):
        return Err(error);
    }
    final account = _tokens.account;
    final message = loginApprovalMessage(
      origin: account.origin,
      requestId: payload.requestId,
      challenge: payload.challenge,
      deviceId: account.deviceId,
    );
    final Uint8List signature;
    switch (await _signWithBiometrics(message, promptOf(details))) {
      case Ok(:final value):
        signature = value;
      case Err(:final error):
        return Err(KeyOperationFailed(error));
    }
    final approval = SignedDeviceRequest(
      deviceId: account.deviceId,
      signature: signature,
    );
    return switch (await _client.approveLoginRequest(
      payload.requestId,
      approval,
    )) {
      Ok() => Ok(details),
      Err(:final error) => Err(ApiCallFailed(error)),
    };
  }

  // A megnyitás egy `401` után egyszer újrapróbál friss tokennel: a tárolt
  // token a szerveren már lejárhatott vagy törlődhetett (V7).
  Future<Result<BrowserLoginDetails, WebAccessError>> _open(
    LoginQrPayload payload,
  ) async {
    for (var attempt = 0; ; attempt++) {
      final String token;
      switch (await _tokens.token()) {
        case Ok(:final value):
          token = value;
        case Err(:final error):
          return Err(error);
      }
      final opened = await _client.openLoginRequest(
        payload.requestId,
        challenge: payload.challenge,
        deviceToken: token,
      );
      switch (opened) {
        case Ok(:final value):
          return Ok(value);
        case Err(error: WebServerFailure(error: NotAuthenticated()))
            when attempt == 0:
          _tokens.invalidate();
        case Err(:final error):
          return Err(ApiCallFailed(error));
      }
    }
  }
}
