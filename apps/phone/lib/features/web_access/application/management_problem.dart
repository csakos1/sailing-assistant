import 'package:flutter/foundation.dart';
import 'package:phone/features/web_access/application/scan_problem.dart';
import 'package:phone/features/web_access/application/web_access_error.dart';
import 'package:phone/features/web_access/data/web_api_failure.dart';
import 'package:phone/features/web_access/data/web_key_operations.dart';
import 'package:race_archive_api/race_archive_api.dart';

/// Amit a kezelőképernyők egy hívás hibájáról mutatnak (ADR 0051 Addendum
/// 10 Z3).
@immutable
sealed class ManagementProblem {
  const ManagementProblem();
}

/// A szerver nem érhető el, vagy érthetetlen választ adott: „Nincs
/// kapcsolat a szerverrel" + „Újra" (H11).
final class ServerUnreachable extends ManagementProblem {
  const ServerUnreachable();
}

/// A telefont visszavonták, vagy a kulcsa elveszett (Z4).
final class PhoneRevoked extends ManagementProblem {
  const PhoneRevoked();
}

/// A kérelem vagy kihívás már nem érvényes (pl. egy másik telefon közben
/// döntött): a lista újratölt.
final class NoLongerValid extends ManagementProblem {
  const NoLongerValid();
}

/// Túl sok próbálkozás; [minutes] perc múlva lehet újra.
final class TryAgainLater extends ManagementProblem {
  /// Várakozás [minutes] percig (legalább 1).
  const TryAgainLater(this.minutes);

  /// A várakozás percben, felfelé kerekítve.
  final int minutes;
}

/// Minden más hiba: „Nem sikerült", a részlet a konzolra megy (V6).
final class ActionFailed extends ManagementProblem {
  const ActionFailed();
}

/// Egy [error] hiba leképezése, vagy `null`, ha a felhasználó maga vetette
/// el az ujjlenyomat-ablakot (Z3: csendes).
///
/// Egy `NotAuthenticated` az `AuthorizedCall` újrapróbája után azt jelenti,
/// hogy a szerver nem fogadja el a telefon kulcsát, ezért visszavonásnak
/// számít, mint a beolvasónál.
ManagementProblem? managementProblemOf(WebAccessError error) => switch (error) {
  ApiCallFailed(:final failure) => _apiProblemOf(failure),
  KeyOperationFailed(:final failure) => switch (failure) {
    KeyOperationFailure.canceled => null,
    KeyOperationFailure.keyMissing => const PhoneRevoked(),
    KeyOperationFailure.unavailable ||
    KeyOperationFailure.lockedOut ||
    KeyOperationFailure.failed => const ActionFailed(),
  },
};

ManagementProblem _apiProblemOf(WebApiFailure failure) => switch (failure) {
  WebNetworkFailure() || WebUnreadableResponse() => const ServerUnreachable(),
  WebServerFailure(error: DeviceRevoked() || NotAuthenticated()) =>
    const PhoneRevoked(),
  WebServerFailure(error: RequestExpired()) => const NoLongerValid(),
  WebServerFailure(error: TooManyAttempts(:final retryAfterSeconds)) =>
    TryAgainLater(minutesToWait(retryAfterSeconds)),
  // Egy szerveroldali hiba (5xx) a felhasználónak ugyanaz, mint az
  // elérhetetlen szerver: később újra lehet próbálni.
  WebServerFailure(:final error) when error.httpStatus >= 500 =>
    const ServerUnreachable(),
  WebServerFailure() => const ActionFailed(),
};
