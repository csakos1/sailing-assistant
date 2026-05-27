import 'dart:async';

import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/providers/gateway_host_provider.dart';

/// A Fázis 3 keep-alive [NmeaStream] providere: a [Nmea0183TcpClient]-et
/// építi a [gatewayHostProvider]-ből, eager kapcsolódik az első olvasáskor,
/// és a Riverpod `onDispose`-on a kliens `dispose()`-át (NEM
/// `disconnect()`-et) regisztrálja, hogy a `events` / `statusChanges` /
/// `rawLines` controllerek is záruljanak (ADR 0006).
///
/// **NEM autoDispose** — vízen a kapcsolat nem állhat le, ha épp nincs
/// UI-listener (§8.1). A Vulcan ↔ `nmea_replay` váltás konfig (a host
/// módosítása), NEM provider-override (ADR 0005 kapcsolat-policy).
final nmeaStreamProvider = Provider<NmeaStream>((ref) {
  final client = Nmea0183TcpClient(host: ref.watch(gatewayHostProvider));
  ref.onDispose(client.dispose);
  unawaited(client.connect());
  return client;
});
