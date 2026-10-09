import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/features/web_access/application/web_access_providers.dart';
import 'package:phone/features/web_access/data/pending_join.dart';

/// A telefon függő csatlakozási kérelme (ADR 0051 Addendum 9 X4).
///
/// A fiókkal egy fájlban él és kizárja azt: egy kérelem mentése vagy
/// törlése után a fiók-provider újraolvassa a fájlt.
class PendingJoinNotifier extends AsyncNotifier<PendingJoin?> {
  @override
  Future<PendingJoin?> build() =>
      ref.read(pendingJoinStoreProvider).readPendingJoin();

  /// A [pending] mentése és közzététele.
  Future<void> save(PendingJoin pending) async {
    await ref.read(pendingJoinStoreProvider).writePendingJoin(pending);
    state = AsyncData(pending);
    ref.invalidate(webAccountProvider);
  }

  /// A függő kérelem törlése. Egy közben mentett fiókot nem töröl: a
  /// fájlt csak akkor üríti, ha az még kérelmet hord.
  Future<void> clear() async {
    final store = ref.read(pendingJoinStoreProvider);
    if (await store.readPendingJoin() != null) await store.delete();
    state = const AsyncData(null);
  }
}
