import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/features/web_access/application/web_access_providers.dart';
import 'package:phone/features/web_access/data/web_account.dart';

/// A telefon webes fiókja (ADR 0051 Addendum 1 H11, Addendum 8 V3).
///
/// Induláskor a tárból olvas; a regisztráció és a fiók-csere a [save]-en
/// és a [clear]-en át írja, így a képernyők (pl. a beolvasó útválasztása)
/// mindig a mentett állapotot látják.
class WebAccountNotifier extends AsyncNotifier<WebAccount?> {
  @override
  Future<WebAccount?> build() => ref.read(webAccountStoreProvider).read();

  /// Az [account] mentése és közzététele.
  Future<void> save(WebAccount account) async {
    await ref.read(webAccountStoreProvider).write(account);
    state = AsyncData(account);
  }

  /// A helyi fiók törlése.
  Future<void> clear() async {
    await ref.read(webAccountStoreProvider).delete();
    state = const AsyncData(null);
  }
}
