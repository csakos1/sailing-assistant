import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/features/web_access/application/management_problem.dart';
import 'package:phone/features/web_access/application/web_access_error.dart';
import 'package:phone/features/web_access/application/web_access_providers.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';

/// A webes munkamenetek egy betöltése: a lista, vagy a hiba (ADR 0051
/// Addendum 10 Z10).
typedef WebSessionsLoad = Result<List<WebSession>, WebAccessError>;

/// A „Webes belépések" képernyő listája (M8, makett 18i/18j).
///
/// Csak amíg a képernyő nyitva van (autoDispose). A hiba adatként jön,
/// nem kivételként, hogy a képernyő a Z3 szerinti sort mutassa; egy
/// visszavont telefon a főképernyő állapotát is visszavonttá teszi (Z4).
class WebSessionsNotifier extends AutoDisposeAsyncNotifier<WebSessionsLoad> {
  @override
  Future<WebSessionsLoad> build() async {
    final calls = ref.watch(authorizedCallProvider);
    if (calls == null) return const Ok(<WebSession>[]);
    final client = ref.watch(
      webAccessApiClientProvider(calls.tokens.account.origin),
    );
    final loaded = await calls.run(
      (token) => client.listSessions(deviceToken: token),
    );
    if (loaded case Err(
      :final error,
    ) when managementProblemOf(error) is PhoneRevoked) {
      ref.read(webAccessStatusProvider.notifier).markRevoked();
    }
    return loaded;
  }

  /// A [sessionId] munkamenet kiléptetése (H9: azonnal), utána a lista
  /// újratölt; a hiba vagy `null`.
  Future<WebAccessError?> endSession(String sessionId) async {
    final error = await ref
        .read(webAccessStatusProvider.notifier)
        .endSession(sessionId);
    if (error == null) ref.invalidateSelf();
    return error;
  }
}
