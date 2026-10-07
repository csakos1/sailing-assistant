import 'package:flutter/foundation.dart';
import 'package:race_archive_api/race_archive_api.dart';

/// Egy webes hitelesítési hívás kudarca a telefon szemszögéből (ADR 0051
/// Addendum 8 V6).
///
/// Sealed, hogy a hibaleképezés kimerítő `switch`-csel döntsön. Mint a
/// web `ApiFailure`-je, de a phone nem függ a webtől.
@immutable
sealed class WebApiFailure {
  const WebApiFailure();
}

/// A kérés el sem jutott a szerverig, a válasz nem érkezett meg, vagy
/// lejárt az időkorlát.
final class WebNetworkFailure extends WebApiFailure {
  /// Hálózati hiba a [message] leírással.
  const WebNetworkFailure(this.message);

  /// A kliens hibaüzenete (naplózásra, nem a felhasználónak).
  final String message;

  @override
  String toString() => 'WebNetworkFailure($message)';
}

/// A szerver a szerződés szerinti hibaválaszt adta.
final class WebServerFailure extends WebApiFailure {
  /// A szerver [error] hibája.
  const WebServerFailure(this.error);

  /// A dekódolt hiba-boríték.
  final ApiError error;

  @override
  String toString() => 'WebServerFailure($error)';
}

/// A válasz nem a szerződés alakja (nem JSON, vagy a dekóder elutasította).
final class WebUnreadableResponse extends WebApiFailure {
  /// Olvashatatlan válasz a [statusCode] státusszal.
  const WebUnreadableResponse(this.statusCode);

  /// A HTTP-státusz.
  final int statusCode;

  @override
  String toString() => 'WebUnreadableResponse($statusCode)';
}
