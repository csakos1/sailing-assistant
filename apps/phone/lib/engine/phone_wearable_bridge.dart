import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/services.dart';
import 'package:phone/features/watch_sync/watch_transport.dart';
import 'package:shared/shared.dart';
import 'package:wearable_bridge/wearable_bridge.dart';

/// A telefon→óra natív transport (e3): a [WatchPayload]-ot egy MethodChannelen
/// átküldi a natív oldalnak, ami a Wearable Data Layer `/race-state` path-jára
/// írja latched `DataItem`-ként (ADR 0015 D5, ADR 0017 A14).
///
/// A [send] illeszkedik a [WatchTransport] szignatúrához, így tear-off-ként
/// (`PhoneWearableBridge().send`) adható a `WatchSyncController`-be. Szerződés
/// (LSP): **nem dob** — a platform-hibát itt nyeljük el és logoljuk, mert a
/// passzív óra a következő change-detectnél úgyis újraszinkronizál. A natív
/// handlert az e3.2 köti be; addig a hívás `MissingPluginException`-t ad, amit
/// szintén elnyelünk.
class PhoneWearableBridge {
  /// Létrehozza a hidat. A [channel] tesztben felülírható (DIP); éles esetben a
  /// `com.csakos.foretack/wearable` csatorna.
  PhoneWearableBridge({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(wearableMethodChannelName);

  static const String _putRaceState = 'putRaceState';

  final MethodChannel _channel;

  /// A [payload]-ot JSON-stringként átküldi a natív oldalnak a `putRaceState`
  /// metóduson. Bármely platform-hibára (vagy a még be nem kötött natív handler
  /// `MissingPluginException`-jére) némán logol; sosem dob.
  Future<void> send(WatchPayload payload) async {
    try {
      await _channel.invokeMethod<void>(
        _putRaceState,
        jsonEncode(payload.toJson()),
      );
    } on Exception catch (error) {
      developer.log('Óra-push sikertelen: $error', name: 'WatchPush');
    }
  }
}
