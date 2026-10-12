import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Az engine-session időzítései (ADR 0054 D4, D5). Tesztben felülírható.
@immutable
class EngineSessionTimings {
  /// Az ADR 0054 értékei: 5 mp-es próba, 3 mp-es timeout, és 5 mp a
  /// futó engine átvételére.
  const EngineSessionTimings({
    this.probeInterval = const Duration(seconds: 5),
    this.probeTimeout = const Duration(seconds: 3),
    this.adoptTimeout = const Duration(seconds: 5),
  });

  /// Szünet két gateway-próba között.
  final Duration probeInterval;

  /// Egy próba TCP-kapcsolódásának időkorlátja.
  final Duration probeTimeout;

  /// Egy már futó engine átvételekor ennyi ideig várunk az első
  /// pillanatképre; ha nem jön, az engine újraindul (ADR 0054 E3).
  final Duration adoptTimeout;
}

/// Az [EngineSessionTimings] providere.
final engineSessionTimingsProvider = Provider<EngineSessionTimings>(
  (ref) => const EngineSessionTimings(),
);
