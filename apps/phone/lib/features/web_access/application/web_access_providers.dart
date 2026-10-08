import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:phone/features/web_access/application/authorized_call.dart';
import 'package:phone/features/web_access/application/device_token_source.dart';
import 'package:phone/features/web_access/application/enrollment_flow.dart';
import 'package:phone/features/web_access/application/join_flow.dart';
import 'package:phone/features/web_access/application/join_status_check.dart';
import 'package:phone/features/web_access/application/pending_join_notifier.dart';
import 'package:phone/features/web_access/application/qr_login_flow.dart';
import 'package:phone/features/web_access/application/signed_action_runner.dart';
import 'package:phone/features/web_access/application/web_access_status.dart';
import 'package:phone/features/web_access/application/web_access_status_notifier.dart';
import 'package:phone/features/web_access/application/web_account_notifier.dart';
import 'package:phone/features/web_access/application/web_sessions_notifier.dart';
import 'package:phone/features/web_access/data/biometric_web_key_operations.dart';
import 'package:phone/features/web_access/data/device_identity.dart';
import 'package:phone/features/web_access/data/file_web_account_store.dart';
import 'package:phone/features/web_access/data/pending_join.dart';
import 'package:phone/features/web_access/data/pending_join_store.dart';
import 'package:phone/features/web_access/data/web_access_api_client.dart';
import 'package:phone/features/web_access/data/web_account.dart';
import 'package:phone/features/web_access/data/web_account_store.dart';
import 'package:phone/features/web_access/data/web_key_operations.dart';
import 'package:phone/providers/clock_provider.dart';

// A webes hozzáférés providerei (ADR 0051 Addendum 8 V11). A versenyes
// providerekhez nem nyúlnak, és azok sem ezekhez (V10, H11).

/// A szerver felé menő HTTP-kliens; tesztben `MockClient`-re cserélhető.
final webHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

/// A kliens egy szerverhez, az origója szerint.
final ProviderFamily<WebAccessApiClient, String> webAccessApiClientProvider =
    Provider.family<WebAccessApiClient, String>(
      (ref, origin) =>
          WebAccessApiClient(ref.watch(webHttpClientProvider), origin: origin),
    );

/// A Keystore-kulcsok műveletei; tesztben egy hamis aláíró.
final webKeyOperationsProvider = Provider<WebKeyOperations>(
  (ref) => biometricWebKeyOperations(),
);

/// A telefon neve és típusa.
final readDeviceIdentityProvider = Provider<ReadDeviceIdentity>(
  (ref) => readAndroidDeviceIdentity,
);

/// A fiók tára: egy JSON-fájl az app privát könyvtárában (V3).
final webAccountStoreProvider = Provider<WebAccountStore>(
  (ref) => FileWebAccountStore(getApplicationSupportDirectory),
);

/// A függő csatlakozási kérelem tára: ugyanaz a fájl (Addendum 9 X4).
final pendingJoinStoreProvider = Provider<PendingJoinStore>(
  (ref) => FileWebAccountStore(getApplicationSupportDirectory),
);

/// A telefon neve és típusa egyszer kiolvasva (a 18e-2 „Telefon" sora).
final deviceIdentityProvider = FutureProvider<DeviceIdentity>(
  (ref) => ref.watch(readDeviceIdentityProvider)(),
);

/// A telefon webes fiókja, vagy `null`, ha nincs.
final webAccountProvider =
    AsyncNotifierProvider<WebAccountNotifier, WebAccount?>(
      WebAccountNotifier.new,
    );

/// A telefon függő csatlakozási kérelme, vagy `null`, ha nincs.
final pendingJoinProvider =
    AsyncNotifierProvider<PendingJoinNotifier, PendingJoin?>(
      PendingJoinNotifier.new,
    );

/// Az eszköz-token forrása a mentett fiókhoz; fiók nélkül `null`. A
/// fiók változásakor újraépül, így egy régi fiók tokenje nem marad meg.
final deviceTokenSourceProvider = Provider<DeviceTokenSource?>((ref) {
  final account = ref.watch(webAccountProvider).valueOrNull;
  if (account == null) return null;
  return DeviceTokenSource(
    account: account,
    client: ref.watch(webAccessApiClientProvider(account.origin)),
    signSilently: ref.watch(webKeyOperationsProvider).signSilently,
    now: ref.watch(clockProvider),
  );
});

/// A QR-belépés folyamata a mentett fiókhoz; fiók nélkül `null`.
final qrLoginFlowProvider = Provider<QrLoginFlow?>((ref) {
  final tokens = ref.watch(deviceTokenSourceProvider);
  if (tokens == null) return null;
  return QrLoginFlow(
    client: ref.watch(webAccessApiClientProvider(tokens.account.origin)),
    tokens: tokens,
    signWithBiometrics: ref.watch(webKeyOperationsProvider).signWithBiometrics,
  );
});

/// A regisztráció folyamata.
final enrollmentFlowProvider = Provider<EnrollmentFlow>((ref) {
  final accounts = ref.watch(webAccountProvider.notifier);
  return EnrollmentFlow(
    clientFor: (origin) => ref.read(webAccessApiClientProvider(origin)),
    keys: ref.watch(webKeyOperationsProvider),
    readIdentity: ref.watch(readDeviceIdentityProvider),
    saveAccount: accounts.save,
    clearAccount: accounts.clear,
  );
});

/// A csatlakozás folyamata (V9).
final joinFlowProvider = Provider<JoinFlow>(
  (ref) => JoinFlow(
    clientFor: (origin) => ref.read(webAccessApiClientProvider(origin)),
    keys: ref.watch(webKeyOperationsProvider),
    readIdentity: ref.watch(readDeviceIdentityProvider),
    savePendingJoin: ref.watch(pendingJoinProvider.notifier).save,
  ),
);

/// A függő kérelem lekérdezése (V9, X3).
final joinStatusCheckProvider = Provider<JoinStatusCheck>(
  (ref) => JoinStatusCheck(
    clientFor: (origin) => ref.read(webAccessApiClientProvider(origin)),
    saveAccount: ref.watch(webAccountProvider.notifier).save,
    clearPendingJoin: ref.watch(pendingJoinProvider.notifier).clear,
    deleteKeys: ref.watch(webKeyOperationsProvider).deleteKeys,
    now: ref.watch(clockProvider),
  ),
);

/// Eszköz-tokenes hívások a mentett fiókhoz (Addendum 10 Z3); fiók nélkül
/// `null`.
final authorizedCallProvider = Provider<AuthorizedCall?>((ref) {
  final tokens = ref.watch(deviceTokenSourceProvider);
  return tokens == null ? null : AuthorizedCall(tokens);
});

/// Az ujjlenyomatos műveletek aláírója (Z3); fiók nélkül `null`.
final signedActionRunnerProvider = Provider<SignedActionRunner?>((ref) {
  final calls = ref.watch(authorizedCallProvider);
  if (calls == null) return null;
  return SignedActionRunner(
    client: ref.watch(webAccessApiClientProvider(calls.tokens.account.origin)),
    calls: calls,
    signWithBiometrics: ref.watch(webKeyOperationsProvider).signWithBiometrics,
  );
});

/// A főképernyő szalagja és a visszavont jelzés (Z4, Z5).
final webAccessStatusProvider =
    NotifierProvider<WebAccessStatusNotifier, WebAccessStatus>(
      WebAccessStatusNotifier.new,
    );

/// A webes munkamenetek, amíg a „Webes belépések" nyitva van (Z10).
final AutoDisposeAsyncNotifierProvider<WebSessionsNotifier, WebSessionsLoad>
webSessionsProvider =
    AsyncNotifierProvider.autoDispose<WebSessionsNotifier, WebSessionsLoad>(
      WebSessionsNotifier.new,
    );
