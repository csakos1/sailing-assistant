import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wearable_bridge/wearable_bridge.dart';

/// Az óra → telefon kézi „bója megvan" parancs küldője (DIP): egyetlen,
/// fire-once hívás. Sikerre normálisan kész; hibára (nincs BT-kapcsolat / nincs
/// node) dob, amiből a C-lap „nincs kapcsolat"-ot rajzol (ADR 0024 D5).
/// Tesztben a [roundMarkSenderProvider] override-olható.
typedef RoundMarkSender = Future<void> Function();

/// A round-mark parancs küldője: a `wearable_bridge` natív MethodChannelje
/// (`wearableMethodChannelName`) `sendRoundMark` metódusát hívja, ami az óra
/// natív oldalán `MessageClient.sendMessage`-dzsé fordul (ADR 0024 D4).
final roundMarkSenderProvider = Provider<RoundMarkSender>((ref) {
  const channel = MethodChannel(wearableMethodChannelName);
  return () => channel.invokeMethod<void>(wearableRoundMarkSendMethod);
});
