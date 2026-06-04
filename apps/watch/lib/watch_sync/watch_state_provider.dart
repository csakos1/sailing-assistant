import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:wearable_bridge/wearable_bridge.dart';

/// Az óra natív vételének forrás-absztrakciója (DIP): a nyers JSON-string
/// streamje a Wearable Data Layer `/race-state` path-járól (ADR 0018 A1).
///
/// Tesztben a [watchStateSourceProvider] override-olható platform nélküli fake
/// streammel, így a dekódolás és a provider EventChannel nélkül verifikálható
/// (a phone `WatchTransport` DIP-tükre).
typedef WatchStateSource = Stream<String> Function();

/// A natív hídról érkező [json]-stringet [WatchPayload]-dá dekódolja. Tiszta
/// függvény — közvetlenül round-trip tesztelhető; a dekódolás szándékosan az
/// óra-oldalon van (a plugin DTO-mentes transport, ADR 0018 A1.2).
WatchPayload decodeWatchPayload(String json) =>
    WatchPayload.fromJson(jsonDecode(json) as Map<String, dynamic>);

/// A vételi forrás: éles esetben a `wearable_bridge` EventChannelje
/// (`wearableRaceStateEventChannelName`), amely a beérkező `/race-state`
/// payload JSON-stringjét emittálja. Tesztben override-olva.
final watchStateSourceProvider = Provider<WatchStateSource>((ref) {
  const channel = EventChannel(wearableRaceStateEventChannelName);
  return () => channel.receiveBroadcastStream().cast<String>();
});

/// A megjelenítendő [WatchPayload]-ok streamje az óra UI-jának. Keep-alive (nem
/// autoDispose): a primary kijelző végig figyel (ADR 0016 használati mód); a
/// `loading`/`error`/`data` állapotot az óra UI kezeli (f3b).
final watchStateProvider = StreamProvider<WatchPayload>(
  (ref) => ref.watch(watchStateSourceProvider)().map(decodeWatchPayload),
);
