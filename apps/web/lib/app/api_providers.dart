import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foretack_web/api/archive_api_client.dart';
import 'package:http/http.dart' as http;

/// A böngésző HTTP-kliense; a provider eldobásakor bezárul.
///
/// A webes buildben a `http.Client()` a böngésző `fetch`-ét használja. A
/// tesztek az [archiveApiClientProvider]-t írják felül egy `MockClient`-tel.
final Provider<http.Client> httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

/// Az archívum API-kliense, az oldal saját címéhez képest (ADR 0048
/// Addendum 4 K1, K5): élesben és lokálisan is ugyanaz az origin.
final Provider<ArchiveApiClient> archiveApiClientProvider =
    Provider<ArchiveApiClient>(
      (ref) => ArchiveApiClient(
        ref.watch(httpClientProvider),
        baseUri: Uri.base,
      ),
    );
