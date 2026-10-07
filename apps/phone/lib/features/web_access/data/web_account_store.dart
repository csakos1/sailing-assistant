import 'package:phone/features/web_access/data/web_account.dart';

/// A telefon webes fiókjának tára (ADR 0051 Addendum 8 V3).
///
/// Külön interfész, hogy a folyamatok és a tesztek ne a fájlrendszerhez
/// kötődjenek; az éles megvalósítás a `FileWebAccountStore`.
abstract interface class WebAccountStore {
  /// A tárolt fiók, vagy `null`, ha nincs (vagy nem olvasható).
  Future<WebAccount?> read();

  /// Az [account] mentése, a korábbit felülírva.
  Future<void> write(WebAccount account);

  /// A tárolt fiók törlése; ha nincs, nem hiba.
  Future<void> delete();
}
