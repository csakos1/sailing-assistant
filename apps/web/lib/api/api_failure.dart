import 'package:flutter/foundation.dart';
import 'package:race_archive_api/race_archive_api.dart';

/// Egy API-hívás kudarca a web szemszögéből (ADR 0048 Addendum 4 K2).
///
/// Sealed, hogy a képernyő kimerítő `switch`-csel döntse el, mit mond. Az
/// `Exception`-t azért implementálja, mert a Riverpod `FutureProvider`-e a
/// hibát dobott értékként viszi az `AsyncValue.error`-ba.
@immutable
sealed class ApiFailure implements Exception {
  const ApiFailure();
}

/// A kérés el sem jutott a szerverig, vagy a válasz nem érkezett meg.
final class NetworkFailure extends ApiFailure {
  /// Hálózati hiba a [message] leírással.
  const NetworkFailure(this.message);

  /// A kliens hibaüzenete (naplózásra, nem a felhasználónak).
  final String message;

  @override
  String toString() => 'NetworkFailure($message)';
}

/// A szerver a szerződés szerinti hibaválaszt adta.
final class ServerFailure extends ApiFailure {
  /// A szerver [error] hibája.
  const ServerFailure(this.error);

  /// A dekódolt hiba-boríték.
  final ApiError error;

  @override
  String toString() => 'ServerFailure($error)';
}

/// A válasz nem a szerződés alakja: nem JSON, vagy a dekóder elutasította.
final class UnreadableResponse extends ApiFailure {
  /// Olvashatatlan válasz a [statusCode] státusszal; a [decodeError] a
  /// dekóder hibája, ha a JSON maga rendben volt.
  const UnreadableResponse(this.statusCode, {this.decodeError});

  /// A HTTP-státusz.
  final int statusCode;

  /// A dekódolás hibája, ha van.
  final DecodeError? decodeError;

  @override
  String toString() => 'UnreadableResponse($statusCode, $decodeError)';
}
