// A telefon↔óra natív transport megosztott konstansai (egy igazságforrás:
// Dart MethodChannel, natív WearableBridgePlugin, és az óra-vételi oldal — 7-bg-f).

/// A `MethodChannel` neve, amin a telefon a `WatchPayload` JSON-ját küldi.
const String wearableMethodChannelName = 'com.csakos.foretack/wearable';

/// A `DataItem` path-ja a Wearable Data Layeren (latched állapot).
const String wearableRaceStatePath = '/race-state';
