import 'dart:async';

import 'package:data/src/persistence/app_database.dart';
import 'package:domain/domain.dart';

/// A [TelemetryLogger] Drift-alapú, bufferelt implementációja (ADR 0008 D4).
///
/// A nyers mondatok 5–10 Hz-en érkeznek; mondatonként kommittálni
/// megfojtaná az SQLite-ot. Ezért a logger pufferel, és batch-ben ír, ha
/// (a) a puffer eléri a `maxBufferSize`-t, vagy (b) lejár a `flushInterval`
/// az első pufferelt mondat óta — amelyik előbb. A [dispose] a maradékot is
/// kiírja és leállítja a timert.
class TelemetryLoggerImpl implements TelemetryLogger {
  /// A `database` a cél Drift adatbázis. A `maxBufferSize` és a
  /// `flushInterval` a §9.4 alapértékeivel jön (100 / 1 s); a tesztek
  /// determinizmusa miatt injektálható.
  TelemetryLoggerImpl(
    this._database, {
    int maxBufferSize = 100,
    Duration flushInterval = const Duration(seconds: 1),
  }) : _maxBufferSize = maxBufferSize,
       _flushInterval = flushInterval;

  final AppDatabase _database;
  final int _maxBufferSize;
  final Duration _flushInterval;
  final List<TelemetryRecord> _buffer = [];
  Timer? _flushTimer;
  bool _isDisposed = false;

  @override
  Future<void> log(TelemetryRecord record) async {
    // Lezárás után a kósza mondatokat eldobjuk — nincs új timer, nincs
    // erőforrás-szivárgás (a stream-leiratkozás és a dispose között
    // becsúszó sor ellen).
    if (_isDisposed) {
      return;
    }
    _buffer.add(record);
    if (_buffer.length >= _maxBufferSize) {
      await _flush();
      return;
    }
    // Az első pufferelt mondat indítja a flush-ablakot; a ??= miatt a timer
    // NEM csúszik minden új mondattal (legfeljebb _flushInterval a
    // legrégebbi pufferelt mondat óta).
    _flushTimer ??= Timer(_flushInterval, () => unawaited(_flush()));
  }

  @override
  Future<void> dispose() async {
    _isDisposed = true;
    await _flush();
  }

  /// A puffer kiírása egy batch-ben, majd a timer leállítása. Üres puffernél
  /// no-op. A timer-cancel és a puffer-snapshot a write ELŐTT történik, hogy
  /// a write közben érkező mondatok már a következő ablakba kerüljenek.
  Future<void> _flush() async {
    _flushTimer?.cancel();
    _flushTimer = null;
    if (_buffer.isEmpty) {
      return;
    }
    final pending = List<TelemetryRecord>.of(_buffer);
    _buffer.clear();
    await _database.batch((batch) {
      batch.insertAll(_database.telemetryRecords, [
        for (final record in pending) _toCompanion(record),
      ]);
    });
  }

  /// Domain [TelemetryRecord] → Drift companion. A `decodedJson` kimarad
  /// (absent → null), a sor `id` autoIncrement (ADR 0008 D9).
  TelemetryRecordsCompanion _toCompanion(TelemetryRecord record) {
    return TelemetryRecordsCompanion.insert(
      raceId: record.raceId,
      timestamp: record.timestamp,
      rawSentence: record.rawSentence,
    );
  }
}
