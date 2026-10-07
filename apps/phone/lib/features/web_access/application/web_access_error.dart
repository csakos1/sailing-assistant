import 'package:flutter/foundation.dart';
import 'package:phone/features/web_access/data/web_api_failure.dart';
import 'package:phone/features/web_access/data/web_key_operations.dart';

/// Egy webes hozzáférési folyamat hibája: vagy a szerver felé menő hívás,
/// vagy egy kulcsművelet bukott el (ADR 0051 Addendum 8 V6–V8).
@immutable
sealed class WebAccessError {
  const WebAccessError();
}

/// A szerver felé menő hívás bukott el.
final class ApiCallFailed extends WebAccessError {
  /// A [failure] hívás-hiba.
  const ApiCallFailed(this.failure);

  /// A hívás hibája.
  final WebApiFailure failure;

  @override
  String toString() => 'ApiCallFailed($failure)';
}

/// Egy kulcsművelet (létrehozás, aláírás) bukott el.
final class KeyOperationFailed extends WebAccessError {
  /// A [failure] kulcs-hiba.
  const KeyOperationFailed(this.failure);

  /// A kulcsművelet hibája.
  final KeyOperationFailure failure;

  @override
  String toString() => 'KeyOperationFailed($failure)';
}
