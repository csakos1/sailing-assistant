import 'package:flutter/foundation.dart';
import 'package:phone/features/web_access/application/scan_problem.dart';
import 'package:phone/features/web_access/data/pending_join.dart';
import 'package:phone/features/web_access/data/web_account.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';

/// Mit tegyen az app egy beolvasott QR-kóddal (ADR 0051 Addendum 8 V5,
/// Addendum 9 X5).
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

/// Fiók nélküli telefon belépési QR-ja: csatlakozás (V9).
final class JoinScan extends ScanRoute {
  /// Csatlakozás a [payload] belépési kéréshez; a [draftName] egy korábbi,
  /// lejárt QR-ral beírt név (X2).
  const JoinScan(this.payload, {this.draftName});

  /// A belépési QR tartalma.
  final LoginQrPayload payload;

  /// A megőrzött név: ha van, az app űrlap nélkül az ujjlenyomatot kéri.
  final String? draftName;
}

/// Egy már beküldött kérelem: a 18e-2 jön, új kérelem nem (X5).
final class PendingJoinScan extends ScanRoute {
  /// A [pending] kérelem.
  const PendingJoinScan(this.pending);

  /// A függő kérelem.
  final PendingJoin pending;
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

/// A beolvasott [text] és a helyi állapot → [ScanRoute] (V5, X5 táblája).
///
/// A helyi állapot a mentett [account], egy élő [pendingJoin] (a lejártat
/// a hívó előtte eldobja) és a megőrzött [draftName]. A fiók és a kérelem
/// a fájlban kizárja egymást (X4), ezért a fiók dönt először.
///
/// A szöveg körüli szóközt és sortörést levágja: a CLI kimenete a
/// `| qrencode` csövön át záró sortöréssel kerül a QR-be (D3).
///
/// Pure: a beolvasó képernyő csak végrehajtja a döntést.
ScanRoute routeScan(
  String text,
  WebAccount? account, {
  PendingJoin? pendingJoin,
  String? draftName,
}) => switch (decodeQrPayload(text.trim())) {
  Err(error: QrPayloadError.unsupportedVersion) => const ScanRejected(
    UnsupportedCode(),
  ),
  Err() => const ScanRejected(NotForetackCode()),
  Ok(value: final LoginQrPayload payload) => _routeLogin(
    payload,
    account,
    pendingJoin: pendingJoin,
    draftName: draftName,
  ),
  // Egy függő kérelem mellett is megerősítés nélkül: regisztrációs QR-t
  // csak a tulajdonos kap a CLI-ből (X5).
  Ok(value: final EnrollQrPayload payload) => EnrollScan(
    payload,
    replacing: account,
  ),
};

ScanRoute _routeLogin(
  LoginQrPayload payload,
  WebAccount? account, {
  required PendingJoin? pendingJoin,
  required String? draftName,
}) {
  if (account != null) {
    if (account.origin != payload.origin) {
      return ScanRejected(ForeignServer(hostOfOrigin(payload.origin)));
    }
    return LoginScan(payload, account);
  }
  if (pendingJoin != null) {
    // A panel a beolvasott kód szerverét nevezi meg, mint a fióknál.
    if (pendingJoin.origin != payload.origin) {
      return ScanRejected(ForeignServer(hostOfOrigin(payload.origin)));
    }
    return PendingJoinScan(pendingJoin);
  }
  return JoinScan(payload, draftName: draftName);
}
