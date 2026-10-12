import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/engine/gateway_probe.dart';
import 'package:phone/providers/engine_session_timings_provider.dart';
import 'package:phone/providers/gateway_host_provider.dart';

/// A gateway-próba (ADR 0054 D4): ugyanarra a hostra és portra, amire az
/// engine kapcsolódik. Tesztben felülírható.
final gatewayProbeProvider = Provider<GatewayProbe>(
  (ref) => tcpGatewayProbe(
    host: ref.watch(gatewayHostProvider),
    timeout: ref.watch(engineSessionTimingsProvider).probeTimeout,
  ),
);
