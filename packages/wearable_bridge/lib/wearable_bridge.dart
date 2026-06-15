// A telefon↔óra natív transport megosztott konstansai (egy igazságforrás:
// Dart MethodChannel, natív WearableBridgePlugin, és az óra-vételi oldal — 7-bg-f).

/// A `MethodChannel` neve, amin a telefon a `WatchPayload` JSON-ját küldi, és
/// amin az óra a `roundMark` parancsot indítja (ADR 0024).
const String wearableMethodChannelName = 'com.csakos.foretack/wearable';

/// A `DataItem` path-ja a Wearable Data Layeren (latched állapot).
const String wearableRaceStatePath = '/race-state';

/// Az óra-oldali vétel EventChannel-jének neve (ADR 0018 A1): a natív listener
/// ezen emittálja a beérkező `/race-state` payload JSON-stringjét.
const String wearableRaceStateEventChannelName =
    'com.csakos.foretack/wearable/events';

/// Az óra → telefon kézi „bója megvan" parancs `MessageClient`-path-ja
/// (ADR 0024 D2). Egyszeri parancs, üres payloaddal.
const String wearableRoundMarkPath = '/round-mark';

/// A `MethodChannel`-metódus neve, amin az óra a `roundMark` parancsot küldi a
/// natív oldalnak (ADR 0024 D4).
const String wearableRoundMarkSendMethod = 'sendRoundMark';

/// A telefon-oldali parancs-vétel EventChannel-jének neve (ADR 0024 D3): a natív
/// `MessageClient` listener ezen jelzi a beérkező `/round-mark` parancsot a
/// service-izolátumnak.
const String wearableRoundMarkEventChannelName =
    'com.csakos.foretack/wearable/round-mark';
