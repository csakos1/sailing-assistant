import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A Vulcan / NMEA gateway hosztja a `Nmea0183TcpClient`-hez.
///
/// Default: a Vulcan WiFi hotspot fix címe (`192.168.76.1`). A `nmea_replay`
/// ellen futtatva ezt teszt-időben felülírjuk `localhost`-ra (konfig, NEM
/// provider-override — a kapcsolat-réteget változatlanul hagyjuk; ADR 0006).
final gatewayHostProvider = Provider<String>((ref) => '192.168.76.1');
