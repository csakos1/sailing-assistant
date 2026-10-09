import 'dart:typed_data';

import 'package:phone/features/web_access/application/web_access_error.dart';
import 'package:phone/features/web_access/data/web_access_api_client.dart';
import 'package:phone/features/web_access/data/web_account.dart';
import 'package:phone/features/web_access/data/web_key_operations.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';

/// A 15 perces eszköz-token forrása (ADR 0051 Addendum 3 K3, Addendum 8
/// V7).
///
/// A token csak memóriában él. A lejárata előtt [renewBefore]-rel új jön,
/// hogy egy hosszabb folyamat közben ne járjon le; egy `401` után a hívó
/// az [invalidate]-tel dobja el, és egyszer újat kér.
class DeviceTokenSource {
  /// Forrás az [account] fiókhoz, a [_client] szerverén, a [_signSilently]
  /// eszközkulccsal, a [_now] órával.
  DeviceTokenSource({
    required this.account,
    required WebAccessApiClient client,
    required SignSilently signSilently,
    required DateTime Function() now,
  }) : _client = client,
       _signSilently = signSilently,
       _now = now;

  /// Ennyivel a lejárat előtt kér új tokent.
  static const Duration renewBefore = Duration(minutes: 1);

  /// A fiók, amelynek az eszköze a tokent kéri.
  final WebAccount account;

  final WebAccessApiClient _client;
  final SignSilently _signSilently;
  final DateTime Function() _now;

  IssuedSecret? _cached;

  /// Egy érvényes eszköz-token: a tárolt, ha még elég ideig él, különben
  /// egy új a kihívás → csendes aláírás → token úton.
  Future<Result<String, WebAccessError>> token() async {
    final cached = _cached;
    if (cached != null &&
        _now().isBefore(cached.expiresAt.subtract(renewBefore))) {
      return Ok(cached.value);
    }
    _cached = null;
    final String challenge;
    switch (await _client.issueDeviceChallenge(account.deviceId)) {
      case Ok(:final value):
        challenge = value.value;
      case Err(:final error):
        return Err(ApiCallFailed(error));
    }
    final message = deviceTokenMessage(
      origin: account.origin,
      deviceId: account.deviceId,
      challenge: challenge,
    );
    final Uint8List signature;
    switch (await _signSilently(message)) {
      case Ok(:final value):
        signature = value;
      case Err(:final error):
        return Err(KeyOperationFailed(error));
    }
    final issued = await _client.issueDeviceToken(
      SignedDeviceRequest(
        deviceId: account.deviceId,
        challenge: challenge,
        signature: signature,
      ),
    );
    switch (issued) {
      case Ok(:final value):
        _cached = value;
        return Ok(value.value);
      case Err(:final error):
        return Err(ApiCallFailed(error));
    }
  }

  /// A tárolt token eldobása (pl. egy `401` után).
  void invalidate() => _cached = null;
}
