// A telefon↔óra natív transport megosztott konstansai (egy igazságforrás:
// Dart MethodChannel, natív WearableBridgePlugin, és az óra-vételi oldal — 7-bg-f).

/// A `MethodChannel` neve, amin a telefon a `WatchPayload` JSON-ját küldi.
const String wearableMethodChannelName = 'com.csakos.foretack/wearable';

/// A `DataItem` path-ja a Wearable Data Layeren (latched állapot).
const String wearableRaceStatePath = '/race-state';

/// Az óra-oldali vétel EventChannel-jének neve (ADR 0018 A1): a natív listener
/// ezen emittálja a beérkező `/race-state` payload JSON-stringjét.
const String wearableRaceStateEventChannelName =
    'com.csakos.foretack/wearable/events';
