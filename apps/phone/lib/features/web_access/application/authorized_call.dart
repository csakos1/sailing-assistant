import 'package:phone/features/web_access/application/device_token_source.dart';
import 'package:phone/features/web_access/application/web_access_error.dart';
import 'package:phone/features/web_access/data/web_api_failure.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';

/// Egy eszköz-tokennel küldött kérés, a token megkapásával.
typedef TokenCall<T> =
    Future<Result<T, WebApiFailure>> Function(String deviceToken);

/// Egy hívás eszköz-tokennel (ADR 0051 Addendum 10 Z3).
///
/// Token → hívás; egy `401` után a token eldobása és egyszer új: a tárolt
/// token a szerveren már lejárhatott vagy törlődhetett (Addendum 8 V7). A
/// második `401` már a hívó hibája (a telefon kulcsát nem fogadják el).
class AuthorizedCall {
  /// Hívó a [tokens] eszköz-tokenjeivel.
  AuthorizedCall(this.tokens);

  /// A tokenek forrása; a fiók és az origó is innen jön.
  final DeviceTokenSource tokens;

  /// A [send] kérés futtatása egy érvényes tokennel.
  Future<Result<T, WebAccessError>> run<T>(TokenCall<T> send) async {
    for (var attempt = 0; ; attempt++) {
      final String token;
      switch (await tokens.token()) {
        case Ok(:final value):
          token = value;
        case Err(:final error):
          return Err(error);
      }
      switch (await send(token)) {
        case Ok(:final value):
          return Ok(value);
        case Err(error: WebServerFailure(error: NotAuthenticated()))
            when attempt == 0:
          tokens.invalidate();
        case Err(:final error):
          return Err(ApiCallFailed(error));
      }
    }
  }
}
