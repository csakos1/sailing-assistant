import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:race_archive_api/race_archive_api.dart';

/// A csatlakozáshoz beírt név, amíg a kérelem el nem ment (ADR 0051
/// Addendum 9 X2).
///
/// Csak memóriában él: egy lejárt QR után a következő beolvasás ezzel
/// űrlap nélkül kéri az ujjlenyomatot; az app újraindítása eldobja.
class JoinNameDraft extends Notifier<String?> {
  @override
  String? build() => null;

  /// A [name] megőrzése normalizálva; egy nem elfogadható név törli a
  /// vázlatot.
  void remember(String name) => state = normalizeDisplayName(name);

  /// A vázlat eldobása.
  void forget() => state = null;
}
