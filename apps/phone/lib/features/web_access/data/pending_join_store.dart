import 'package:phone/features/web_access/data/pending_join.dart';

/// A függő csatlakozási kérelem tára (ADR 0051 Addendum 9 X4).
///
/// Ugyanabban a fájlban él, mint a fiók, és kizárja azt: egy kérelem
/// mentése a fiókot, egy fiók mentése a kérelmet írja felül.
abstract interface class PendingJoinStore {
  /// A tárolt kérelem, vagy `null`, ha nincs (vagy nem olvasható).
  Future<PendingJoin?> readPendingJoin();

  /// A [pending] mentése; a fájl korábbi tartalmát felülírja.
  Future<void> writePendingJoin(PendingJoin pending);

  /// A fájl törlése (a kérelemmel együtt); ha nincs, nem hiba.
  Future<void> delete();
}
