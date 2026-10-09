import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:foretack_web/api/api_failure.dart';
import 'package:foretack_web/auth/auth_api_client.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';

/// A QR-belépés szakasza (ADR 0051 Addendum 7 P4).
enum QrSignInPhase {
  /// Az első kérés még úton van; nincs mit mutatni.
  starting,

  /// A QR látszik (17a), a visszaszámlálóval.
  showing,

  /// Egy telefon megnyitotta, ujjlenyomatra vár (17c).
  awaitingPhone,

  /// Csatlakozási kérelem, a tulajdonosra vár (17d-1).
  awaitingOwner,

  /// Nem sikerült kérést nyitni; a vezérlő magától újra próbálja.
  unavailable,
}

/// A QR-belépés állapotgépe (P4).
///
/// Kérést nyit, 1,5 mp-enként kérdez, a 60 mp-et és a 10 percet a válasz
/// megérkezésétől méri, és lejáratkor újat nyit. A visszaszámlálás
/// másodperces ütemekből áll, nem a gép órájából: egy elcsúszott gépidő
/// így nem rontja el, a kérés valódi lejáratát pedig úgyis a `poll`
/// mondja meg (egy háttérbe tett lapon a böngésző ritkítja az ütemeket).
///
/// Minden kérés egy „generációt" kap; egy régebbi kérésre késve érkező
/// válasz nem írja felül az újabbat.
class QrSignInController extends ChangeNotifier {
  /// Vezérlő a [client] kliens fölött; a sikeres belépést az
  /// [onSignedIn] kapja.
  QrSignInController({
    required AuthApiClient client,
    required void Function(AccountInfo account) onSignedIn,
  }) : _client = client,
       _onSignedIn = onSignedIn;

  /// A QR élettartama a megjelenésétől (ADR 0051 D4).
  static const int qrSeconds = 60;

  /// A csatlakozási kérelem várakozása a böngészőben (Addendum 3 K5).
  static const int joinSeconds = 600;

  /// A lekérdezés üteme.
  static const Duration pollInterval = Duration(milliseconds: 1500);

  /// Ennyi egymás utáni sikertelen lekérdezés után jelez a web (P4).
  static const int offlineAfterFailures = 3;

  /// Az újranyitás várakozása egy sikertelen kérés után, ha a szerver nem
  /// mondott mást.
  static const Duration retryDelay = Duration(seconds: 5);

  final AuthApiClient _client;
  final void Function(AccountInfo account) _onSignedIn;

  QrSignInPhase _phase = QrSignInPhase.starting;
  String? _requestId;
  String? _qrText;
  int _secondsLeft = 0;
  bool _showsExpiredNotice = false;
  int _failedPolls = 0;
  bool _isOffline = false;

  int _generation = 0;
  bool _isPolling = false;
  bool _isDisposed = false;
  Timer? _tickTimer;
  Timer? _pollTimer;
  Timer? _retryTimer;

  /// A szakasz.
  QrSignInPhase get phase => _phase;

  /// A QR szövege; `null`, amíg nincs kérés.
  String? get qrText => _qrText;

  /// A hátralévő másodpercek a [phase] szerinti visszaszámlálóban.
  int get secondsLeft => _secondsLeft;

  /// Az előző kérés megnyitva vagy csatlakozva járt le (17d-2): a felirat
  /// helyén „Lejárt — olvasd be újra" áll a következő frissítésig.
  bool get showsExpiredNotice => _showsExpiredNotice;

  /// A szerver most nem érhető el (P4).
  bool get isOffline => _isOffline;

  /// Az első kérés megnyitása.
  void start() => unawaited(_openRequest(showsExpiredNotice: false));

  /// „Vissza a QR-kódhoz": a kérést eldobja, újat nyit (Addendum 1 H2).
  ///
  /// A szerveren nincs eldobó végpont: a régi kérés magától lejár, és a
  /// kötő-cookie-t az új kérés felülírja.
  void restart() => unawaited(_openRequest(showsExpiredNotice: false));

  Future<void> _openRequest({required bool showsExpiredNotice}) async {
    final generation = ++_generation;
    _stopTimers();
    final result = await _client.openLoginRequest();
    if (_isDisposed || generation != _generation) return;
    switch (result) {
      case Ok(value: final ticket):
        _showTicket(ticket, generation, showsExpiredNotice: showsExpiredNotice);
      case Err(:final error):
        _scheduleRetry(error, showsExpiredNotice: showsExpiredNotice);
    }
    notifyListeners();
  }

  void _showTicket(
    LoginRequestTicket ticket,
    int generation, {
    required bool showsExpiredNotice,
  }) {
    _phase = QrSignInPhase.showing;
    _requestId = ticket.requestId;
    _qrText = ticket.qrText;
    _secondsLeft = qrSeconds;
    _showsExpiredNotice = showsExpiredNotice;
    _failedPolls = 0;
    _isOffline = false;
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _pollTimer = Timer.periodic(
      pollInterval,
      (_) => unawaited(_poll(generation)),
    );
  }

  // A régi QR a szerveren már nem él, ezért nem marad látható.
  void _scheduleRetry(ApiFailure error, {required bool showsExpiredNotice}) {
    _phase = QrSignInPhase.unavailable;
    _requestId = null;
    _qrText = null;
    _isOffline = true;
    final delay = switch (error) {
      ServerFailure(error: TooManyAttempts(:final retryAfterSeconds)) =>
        Duration(seconds: retryAfterSeconds),
      _ => retryDelay,
    };
    _retryTimer = Timer(
      delay,
      () => unawaited(_openRequest(showsExpiredNotice: showsExpiredNotice)),
    );
  }

  void _tick() {
    if (_secondsLeft > 0) _secondsLeft--;
    if (_phase == QrSignInPhase.showing && _secondsLeft == 0) {
      // 17b: a QR magától frissül.
      unawaited(_openRequest(showsExpiredNotice: false));
      return;
    }
    notifyListeners();
  }

  Future<void> _poll(int generation) async {
    final requestId = _requestId;
    if (_isPolling || requestId == null) return;
    _isPolling = true;
    final result = await _client.pollLoginRequest(requestId);
    // Egy régi kérés késő válasza nem szabadítja fel az új lekérdezését.
    if (_isDisposed || generation != _generation) return;
    _isPolling = false;
    switch (result) {
      case Ok(value: final status):
        _failedPolls = 0;
        _isOffline = false;
        _apply(status);
      case Err():
        // Egy kudarc nem állítja meg a lekérdezést (P4).
        _failedPolls++;
        _isOffline = _failedPolls >= offlineAfterFailures;
    }
    if (!_isDisposed && generation == _generation) notifyListeners();
  }

  void _apply(LoginRequestStatus status) {
    switch (status.state) {
      case LoginRequestState.pending:
        break;
      case LoginRequestState.opened:
        _phase = QrSignInPhase.awaitingPhone;
      case LoginRequestState.joinPending:
        if (_phase != QrSignInPhase.awaitingOwner) {
          _phase = QrSignInPhase.awaitingOwner;
          _secondsLeft = joinSeconds;
        }
      case LoginRequestState.expired:
        // Megnyitott vagy csatlakozó kérésnél jelezni kell (17d-2); egy
        // senki által be nem olvasott QR csendben frissül.
        unawaited(
          _openRequest(showsExpiredNotice: _phase != QrSignInPhase.showing),
        );
      case LoginRequestState.signedIn:
        final account = status.account;
        // A dekóder garantálja a fiókot; nélküle a kérés nem használható.
        if (account == null) {
          unawaited(_openRequest(showsExpiredNotice: false));
          return;
        }
        _generation++;
        _stopTimers();
        _onSignedIn(account);
    }
  }

  void _stopTimers() {
    _tickTimer?.cancel();
    _pollTimer?.cancel();
    _retryTimer?.cancel();
    _tickTimer = null;
    _pollTimer = null;
    _retryTimer = null;
    _isPolling = false;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _generation++;
    _stopTimers();
    super.dispose();
  }
}
