import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/engine/engine_gateway_host.dart';

/// A Vulcan / NMEA gateway hosztja a `Nmea0183TcpClient`-hez.
///
/// Az értéket a plain-Dart `engineGatewayHost()` adja (build-időben
/// `--dart-define=FORETACK_GATEWAY_HOST=...`-fal felülírható; ADR 0007 +
/// ARCHITECTURE.md §15.6) — konfig, NEM provider-override, a kapcsolat-réteget
/// változatlanul hagyjuk (ADR 0006). A háttér-engine (izolátum, Riverpod
/// nélkül) ugyanazt a függvényt hívja.
final gatewayHostProvider = Provider<String>((ref) => engineGatewayHost());
