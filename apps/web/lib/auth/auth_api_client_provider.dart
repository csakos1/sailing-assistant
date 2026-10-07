import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foretack_web/app/http_client_provider.dart';
import 'package:foretack_web/auth/auth_api_client.dart';

/// A hitelesítés API-kliense (ADR 0051 Addendum 7 P2), ugyanarról az
/// originről, mint az archívum. A tesztek egy `MockClient`-tel írják felül.
final Provider<AuthApiClient> authApiClientProvider = Provider<AuthApiClient>(
  (ref) => AuthApiClient(ref.watch(httpClientProvider), baseUri: Uri.base),
);
