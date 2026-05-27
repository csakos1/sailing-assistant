import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A NMEA gateway host build-időben felülírható
/// `--dart-define=FORETACK_GATEWAY_HOST=...`-fal. Ha az env var nincs
/// definiálva, a Vulcan WiFi-hotspot fix címét (`192.168.76.1`) adja vissza.
/// Compile-time konstans — egy futáson belül nem váltogatható (ADR 0007).
const String _defaultGatewayHost = String.fromEnvironment(
  'FORETACK_GATEWAY_HOST',
  defaultValue: '192.168.76.1',
);

/// A Vulcan / NMEA gateway hosztja a `Nmea0183TcpClient`-hez.
///
/// Default: a Vulcan WiFi-hotspot fix címe (`192.168.76.1`). Otthoni
/// `nmea_replay` ellen `--dart-define=FORETACK_GATEWAY_HOST=...`-fal írjuk
/// felül (ADR 0007 + ARCHITECTURE.md §15.6) — konfig, NEM provider-override,
/// a kapcsolat-réteget változatlanul hagyjuk (ADR 0006).
final gatewayHostProvider = Provider<String>((ref) => _defaultGatewayHost);
