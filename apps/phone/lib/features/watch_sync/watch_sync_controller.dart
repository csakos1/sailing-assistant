import 'dart:async';

import 'package:phone/features/watch_sync/watch_transport.dart';
import 'package:shared/shared.dart';

/// Vezérli a telefon→óra szinkront: rögzített kadenciával felépíti az aktuális
/// [WatchPayload]-ot, és **csak akkor** küldi a [WatchTransport]-on, ha az
/// érdemben változott az utoljára küldötthez képest (Equatable `==`, ami a
/// `timestamp`-et és a `gpsTimeUtc`-t kihagyja — lásd `WatchPayload`).
///
/// A change-detect logika ([onTick]) timer nélkül, közvetlen hívással
/// tesztelhető; a [start] csupán [interval]-onként hívja az [onTick]-et.
class WatchSyncController {
  /// Létrehozza a vezérlőt. A [buildPayload] az aktuális állapotból állít elő
  /// payloadot (a provider köti a domain-providerekhez); a [transport] küld.
  WatchSyncController({
    required WatchPayload Function() buildPayload,
    required WatchTransport transport,
    this.interval = const Duration(milliseconds: 500),
  }) : _buildPayload = buildPayload,
       _transport = transport;

  /// A change-detect/küldés ciklusideje. Alapértelmezés 500 ms (ADR 0015 D5).
  final Duration interval;

  final WatchPayload Function() _buildPayload;
  final WatchTransport _transport;

  Timer? _timer;
  WatchPayload? _lastSent;

  /// Elindítja a periodikus szinkront. Idempotens: ismételt hívás nem indít
  /// több timert.
  void start() {
    _timer ??= Timer.periodic(interval, (_) => onTick());
  }

  /// Egy ciklus: payload-építés → change-detect → küldés csak változásra.
  void onTick() {
    final payload = _buildPayload();
    if (payload == _lastSent) return;
    _lastSent = payload;
    // A transport szerződése szerint nem dob, ezért nem awaitelünk és nem
    // védekezünk: a passzív óra a következő változásnál újraszinkronizál.
    unawaited(_transport(payload));
  }

  /// Leállítja a timert. A provider `onDispose`-ban hívja.
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
