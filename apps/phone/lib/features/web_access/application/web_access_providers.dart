import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:phone/features/web_access/application/device_token_source.dart';
import 'package:phone/features/web_access/application/enrollment_flow.dart';
import 'package:phone/features/web_access/application/qr_login_flow.dart';
import 'package:phone/features/web_access/application/web_account_notifier.dart';
import 'package:phone/features/web_access/data/biometric_web_key_operations.dart';
import 'package:phone/features/web_access/data/device_identity.dart';
import 'package:phone/features/web_access/data/file_web_account_store.dart';
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

/// A telefon webes fiókja, vagy `null`, ha nincs.
final webAccountProvider =
    AsyncNotifierProvider<WebAccountNotifier, WebAccount?>(
      WebAccountNotifier.new,
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
