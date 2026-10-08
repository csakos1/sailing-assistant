import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/features/web_access/application/web_access_providers.dart';
import 'package:phone/features/web_access/data/web_account.dart';

/// A telefon webes fiókja (ADR 0051 Addendum 1 H11, Addendum 8 V3).
///
/// Induláskor a tárból olvas; a regisztráció és a fiók-csere a [save]-en
/// és a [clear]-en át írja, így a képernyők (pl. a beolvasó útválasztása)
/// mindig a mentett állapotot látják. A fiók egy fájlban él a függő
/// csatlakozási kérelemmel és kizárja azt (Addendum 9 X4), ezért egy
/// írás után a kérelem providere újraolvassa a fájlt.
class WebAccountNotifier extends AsyncNotifier<WebAccount?> {
  @override
  Future<WebAccount?> build() => ref.read(webAccountStoreProvider).read();

  /// Az [account] mentése és közzététele.
  Future<void> save(WebAccount account) async {
    await ref.read(webAccountStoreProvider).write(account);
    state = AsyncData(account);
    ref.invalidate(pendingJoinProvider);
  }

  /// A helyi fiók törlése (egy függő kérelemmel együtt: a regisztráció
  /// azt is eldobja, X5).
  Future<void> clear() async {
    await ref.read(webAccountStoreProvider).delete();
    state = const AsyncData(null);
    ref.invalidate(pendingJoinProvider);
  }
}
