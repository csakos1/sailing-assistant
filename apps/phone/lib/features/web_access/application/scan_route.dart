import 'package:flutter/foundation.dart';
import 'package:phone/features/web_access/application/scan_problem.dart';
import 'package:phone/features/web_access/data/web_account.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';

/// Mit tegyen az app egy beolvasott QR-kóddal (ADR 0051 Addendum 8 V5).
@immutable
sealed class ScanRoute {
  const ScanRoute();
}

/// A kód nem használható; a [problem] panel jön.
final class ScanRejected extends ScanRoute {
  /// Elutasított kód a [problem] panellel.
  const ScanRejected(this.problem);

  /// A hibapanel.
  final ScanProblem problem;
}

/// Belépés a webre a regisztrált fiókkal (V6).
final class LoginScan extends ScanRoute {
  /// Belépés a [payload] kéréssel, az [account] fiókkal.
  const LoginScan(this.payload, this.account);

  /// A belépési QR tartalma.
  final LoginQrPayload payload;

  /// A telefon fiókja; az origója egyezik a QR-éval.
  final WebAccount account;
}

/// Fiók nélküli telefon belépési QR-ja: csatlakozás (V9, A4b).
final class JoinScan extends ScanRoute {
  /// Csatlakozás a [payload] belépési kéréshez.
  const JoinScan(this.payload);

  /// A belépési QR tartalma.
  final LoginQrPayload payload;
}

/// A tulajdonos telefonjának regisztrációja (V8).
final class EnrollScan extends ScanRoute {
  /// Regisztráció a [payload] tokennel; a [replacing] a lecserélendő
  /// helyi fiók, ha van (V1).
  const EnrollScan(this.payload, {this.replacing});

  /// A regisztrációs QR tartalma.
  final EnrollQrPayload payload;

  /// A meglévő helyi fiók; ilyenkor előbb megerősítés kell.
  final WebAccount? replacing;
}

/// A beolvasott [text] és a helyi [account] → [ScanRoute] (V5 táblája).
///
/// A szöveg körüli szóközt és sortörést levágja: a CLI kimenete a
/// `| qrencode` csövön át záró sortöréssel kerül a QR-be (D3).
///
/// Pure: a beolvasó képernyő csak végrehajtja a döntést.
ScanRoute routeScan(String text, WebAccount? account) =>
    switch (decodeQrPayload(text.trim())) {
      Err(error: QrPayloadError.unsupportedVersion) => const ScanRejected(
        UnsupportedCode(),
      ),
      Err() => const ScanRejected(NotForetackCode()),
      Ok(value: final LoginQrPayload payload) => _routeLogin(payload, account),
      Ok(value: final EnrollQrPayload payload) => EnrollScan(
        payload,
        replacing: account,
      ),
    };

ScanRoute _routeLogin(LoginQrPayload payload, WebAccount? account) {
  if (account == null) return JoinScan(payload);
  if (account.origin != payload.origin) {
    return ScanRejected(ForeignServer(hostOfOrigin(payload.origin)));
  }
  return LoginScan(payload, account);
}
