import 'dart:async';
import 'dart:convert';

import 'package:data/src/nmea/client/nmea_connection.dart';
import 'package:data/src/nmea/client/raw_nmea_line_source.dart';
import 'package:data/src/nmea/client/socket_nmea_connection.dart';
//import 'package:data/src/nmea/client/socket_nmea_connection.dart';
import 'package:data/src/nmea/pipeline/nmea_event_pipeline.dart';
import 'package:domain/domain.dart';

/// A domain `NmeaStream` TCP-implementációja: a Vulcan 0183-over-WiFi
/// kimenetéhez (`192.168.76.1:10110`) csatlakozik, a socket nyers byte-jait a
/// stateful [NmeaEventPipeline]-on át domain-eseményekké alakítja, és kiadja az
/// [events] / [statusChanges] streameket. A debug raw-viewer számára egyúttal
/// [RawNmeaLineSource]-ot is implementál: a socket bytes-eit egy második,
/// független `utf8.decoder + LineSplitter` ágon nyers sorokká is felbontja
/// (ADR 0006), így a tesztelt parse-pipeline érintetlen marad.
///
/// A kapcsolat-policyt az ADR 0005 rögzíti (ARCHITECTURE.md 6.4): a belső loop
/// fix `reconnectDelay` (default 2 s) időközönként, végtelenül újrapróbál, és
/// csak a [disconnect] állítja le; a [NmeaEventPipeline]-t (és benne a
/// `WindAggregator`-t) **újrahasználja** a reconnecteken át, így a szél-állapot
/// túléli a szakadást. Status: [connect] → `Connecting`, sikeres socket →
/// `Connected`, szakadás/hiba → `ConnectionError` majd újra `Connecting`,
/// [disconnect] → `Disconnected` (az azonos egymás utáni állapotok de-dupolva).
/// Az [events], a [statusChanges] és a [rawLines] is **broadcast**; a socket
/// egy injektálható [NmeaConnector] mögött van a hardver nélküli teszthez.
class Nmea0183TcpClient implements NmeaStream, RawNmeaLineSource {
  /// Klienst hoz létre; minden paraméter opcionális, a Vulcan-defaultokkal. A
  /// `connector` éles futásban a `connectTcpSocket`, tesztben fake.
  Nmea0183TcpClient({
    String host = _defaultHost,
    int port = _defaultPort,
    NmeaConnector connector = connectTcpSocket,
    Duration connectTimeout = _defaultConnectTimeout,
    Duration reconnectDelay = _defaultReconnectDelay,
  }) : _host = host,
       _port = port,
       _connect = connector,
       _connectTimeout = connectTimeout,
       _reconnectDelay = reconnectDelay;

  static const String _defaultHost = '192.168.76.1';
  static const int _defaultPort = 10110;
  static const Duration _defaultConnectTimeout = Duration(seconds: 6);
  static const Duration _defaultReconnectDelay = Duration(seconds: 2);

  final String _host;
  final int _port;
  final NmeaConnector _connect;
  final Duration _connectTimeout;
  final Duration _reconnectDelay;

  // Egyetlen pipeline a kliens teljes életére: a mapper/aggregator állapota így
  // túléli a reconnectet (ADR 0005, ARCHITECTURE.md 6.4).
  final NmeaEventPipeline _pipeline = NmeaEventPipeline();

  final StreamController<DomainEvent> _events =
      StreamController<DomainEvent>.broadcast();
  final StreamController<ConnectionStatus> _statusChanges =
      StreamController<ConnectionStatus>.broadcast();
  // Hosszú életű (a kliens teljes élete alatt nyitva): a túlélő/kései
  // feliratkozók a reconnecten át is megkapják a következő sorokat. Csak a
  // dispose() zárja (ADR 0006).
  final StreamController<String> _rawLines =
      StreamController<String>.broadcast();

  ConnectionStatus _currentStatus = const Disconnected();

  // true a connect() és a disconnect() közt: ez vezérli a reconnect-loopot.
  bool _shouldRun = false;

  // Az aktuális élő kapcsolat (reconnect/disconnect zárja).
  NmeaConnection? _connection;

  @override
  Stream<DomainEvent> get events => _events.stream;

  @override
  Stream<ConnectionStatus> get statusChanges => _statusChanges.stream;

  @override
  ConnectionStatus get currentStatus => _currentStatus;

  @override
  Stream<String> get rawLines => _rawLines.stream;

  /// Elindítja a kapcsolatot és a reconnect-loopot. Idempotens: ha már fut, nem
  /// csinál semmit. A hibát NEM dobja — a [statusChanges] `ConnectionError`
  /// ágán jelenik meg, hogy a stream vízen ne álljon le.
  @override
  Future<void> connect() async {
    if (_shouldRun) {
      return;
    }
    _shouldRun = true;
    _emit(const Connecting());
    unawaited(_runLoop());
  }

  /// Leállítja a reconnect-loopot, lezárja az élő kapcsolatot, és
  /// `Disconnected`-et emittál. Idempotens.
  @override
  Future<void> disconnect() async {
    if (!_shouldRun) {
      if (_currentStatus is! Disconnected) {
        _emit(const Disconnected());
      }
      return;
    }
    _shouldRun = false;
    // A kapcsolat zárása fejezi be a loopban futó `await for`-t.
    await _closeConnection();
    _emit(const Disconnected());
  }

  /// Végleg elengedi az erőforrásokat (a Riverpod-réteg `onDispose`-ából);
  /// utána a kliens nem használható újra.
  Future<void> dispose() async {
    await disconnect();
    await _events.close();
    await _statusChanges.close();
    await _rawLines.close();
  }

  // A reconnect-loop: amíg fut, csatlakozik, pumpál, majd szakadáskor vár és
  // újrapróbál. A hibát státuszra fordítja, sosem dobja tovább.
  Future<void> _runLoop() async {
    while (_shouldRun) {
      _emit(const Connecting());
      final NmeaConnection connection;
      try {
        connection = await _connect(_host, _port, timeout: _connectTimeout);
      } on Object catch (error) {
        _emit(ConnectionError('Kapcsolati hiba: $error'));
        if (!_shouldRun) {
          break;
        }
        await Future<void>.delayed(_reconnectDelay);
        continue;
      }
      _connection = connection;
      _emit(const Connected());

      // A socket bytes-jeit két független ágra osztjuk: (1) a meglévő
      // parse-pipeline -> events, (2) külön utf8.decoder + LineSplitter ->
      // _rawLines (debug). A broadcast nem pufferel, de a socket adata csak
      // az event-loop (I/O) sorból jön, ami a microtask-sor kiürülése UTÁN
      // fut — ezért a két feliratkozást egy szinkron szeletben (await nélkül)
      // indítjuk, így mindkettő kész az első bájt előtt (ADR 0006).
      final bytes = connection.bytes.asBroadcastStream();

      final rawSub = bytes
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            (line) {
              if (!_rawLines.isClosed) {
                _rawLines.add(line);
              }
            },
            // Debug-ág: a hibát elnyeli (egy utf8-hiba se zavarja a fő ágat).
            onError: (Object _) {},
            cancelOnError: false,
          );

      try {
        await for (final event in _pipeline.transform(bytes)) {
          if (!_events.isClosed) {
            _events.add(event);
          }
        }
      } on Object catch (_) {
        // Pipeline-/socket-hiba = a kapcsolat vége; a reconnect dönt a többiről.
      } finally {
        // A nyers ág subscription-je csak ehhez a kapcsolathoz tartozik;
        // reconnectkor a következő iteráció új broadcast-tel újat hoz létre.
        await rawSub.cancel();
      }

      await _closeConnection();
      if (!_shouldRun) {
        break;
      }
      _emit(const ConnectionError('Kapcsolat megszakadt'));
      await Future<void>.delayed(_reconnectDelay);
    }
  }

  Future<void> _closeConnection() async {
    final connection = _connection;
    _connection = null;
    await connection?.close();
  }

  // Beállítja és kiadja az új státuszt, az azonos egymás utánit de-dupolva
  // (ADR 0005) — a statusChanges így zaj nélkül követhető reconnect-loopban is.
  void _emit(ConnectionStatus status) {
    if (_isSameStatus(_currentStatus, status)) {
      return;
    }
    _currentStatus = status;
    if (!_statusChanges.isClosed) {
      _statusChanges.add(status);
    }
  }

  bool _isSameStatus(ConnectionStatus a, ConnectionStatus b) {
    if (a is ConnectionError && b is ConnectionError) {
      return a.message == b.message;
    }
    return a.runtimeType == b.runtimeType;
  }
}
