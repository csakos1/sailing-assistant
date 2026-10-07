import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// A böngésző HTTP-kliense; a provider eldobásakor bezárul.
///
/// A webes buildben a `http.Client()` a böngésző `fetch`-ét használja. A
/// tesztek az API-kliensek providereit írják felül egy `MockClient`-tel.
final Provider<http.Client> httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});
