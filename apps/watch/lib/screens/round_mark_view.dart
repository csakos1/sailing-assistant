import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared/shared.dart';
import 'package:watch/theme/watch_colors.dart';

/// „C" nézet — Bója-megerősítés (§10.4, ADR 0024). Nagy, kör alakú teal gomb
/// press-and-hold (~1 s) gesztussal és kitöltő gyűrűvel: a szándékos tartás a
/// véletlen léptetés ellen véd. A hold végén send-tick haptic + a parancs
/// küldése; a tényleges léptetést erősebb haptic erősíti meg, amikor a
/// következő payloadban a célbója-név átvált (round-trip-tudatos, explicit ack
/// nélkül). Küldési hibára (nincs kapcsolat) haptic + felirat; ~2 s debounce a
/// dupla-küldés ellen. Ambientben statikus, tompított gomb, interakció nélkül.
class RoundMarkView extends StatefulWidget {
  /// Létrehozza a nézetet a [payload]-dal (a célbója-név forrása), a [colors]
  /// tokenekkel, az [ambient] zászlóval és az [onSend] parancs-küldővel.
  const RoundMarkView({
    required this.payload,
    required this.colors,
    required this.ambient,
    required this.onSend,
    super.key,
  });

  /// A megjelenítendő payload; a `markName` változása a megerősítés jele.
  final WatchPayload payload;

  /// A téma szín-tokenjei.
  final WatchColors colors;

  /// Ambient mód: statikus, tompított, interakció nélkül.
  final bool ambient;

  /// A parancs-küldő (DIP): sikerre kész, hibára dob.
  final Future<void> Function() onSend;

  @override
  State<RoundMarkView> createState() => _RoundMarkViewState();
}

// A C-lap belső állapota: nyugalmi, megerősítésre váró, megerősített, hibás.
enum _RoundStatus { idle, waiting, confirmed, failed }

class _RoundMarkViewState extends State<RoundMarkView>
    with SingleTickerProviderStateMixin {
  // ~1 s tartás a kitöltő gyűrűhöz; completed-re sül el a parancs.
  late final AnimationController _hold;

  _RoundStatus _status = _RoundStatus.idle;

  // A küldéskor rögzített célbója-név; amíg nem null, megerősítésre várunk. A
  // round-trip jele: a payload markName-je ettől eltér (léptetés után a
  // következő bója nevét hozza).
  String? _pendingMarkName;
  Timer? _pendingTimeout;
  DateTime? _lastSentAt;

  @override
  void initState() {
    super.initState();
    _hold = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..addStatusListener(_onHoldStatus);
  }

  @override
  void didUpdateWidget(RoundMarkView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Round-trip megerősítés: ha várunk és a célbója-név átváltott, a léptetés
    // megtörtént — erős haptic + „megkerülve".
    final pending = _pendingMarkName;
    if (pending != null && widget.payload.markName != pending) {
      _pendingTimeout?.cancel();
      _pendingTimeout = null;
      _pendingMarkName = null;
      unawaited(HapticFeedback.heavyImpact());
      setState(() => _status = _RoundStatus.confirmed);
    }
  }

  @override
  void dispose() {
    _pendingTimeout?.cancel();
    _hold.dispose();
    super.dispose();
  }

  void _onHoldStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      unawaited(_fire());
    }
  }

  // A hold lejárt: debounce, send-tick haptic, küldés, majd várás a
  // markName-váltásra.
  Future<void> _fire() async {
    _hold.reset();
    final now = DateTime.now();
    final last = _lastSentAt;
    // ~2 s debounce a véletlen ismételt elsülés ellen.
    if (last != null && now.difference(last) < const Duration(seconds: 2)) {
      return;
    }
    _lastSentAt = now;
    await HapticFeedback.selectionClick();

    final markAtSend = widget.payload.markName;
    if (!mounted) return;
    setState(() {
      _status = _RoundStatus.waiting;
      _pendingMarkName = markAtSend;
    });

    try {
      await widget.onSend();
      // Siker: várunk a markName-váltásra; ~5 s után halkan elengedjük (a
      // parancs megérkezhetett, de pl. nincs aktív verseny — a telefon
      // no-op-ja ártalmatlan).
      _pendingTimeout?.cancel();
      _pendingTimeout = Timer(const Duration(seconds: 5), () {
        if (!mounted) return;
        _pendingMarkName = null;
        setState(() => _status = _RoundStatus.idle);
      });
    } on Object {
      // Bármilyen küldési hiba (nincs node / sendMessage failed): a vízen a
      // biztos jelzés a fontos, ezért minden hibát „nincs kapcsolat"-ra
      // egységesítünk.
      _pendingTimeout?.cancel();
      _pendingMarkName = null;
      await HapticFeedback.vibrate();
      if (!mounted) return;
      setState(() => _status = _RoundStatus.failed);
    }
  }

  void _onTapDown(TapDownDetails _) {
    if (_status == _RoundStatus.waiting) return;
    if (_status != _RoundStatus.idle) {
      setState(() => _status = _RoundStatus.idle);
    }
    _hold.forward();
  }

  // Felengedés a tartás vége előtt: a gyűrű visszaürül, nincs küldés.
  void _releaseHold() {
    if (_hold.status != AnimationStatus.completed) {
      _hold.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    if (widget.ambient) {
      return _AmbientRoundButton(colors: colors);
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTapDown: _onTapDown,
            onTapUp: (_) => _releaseHold(),
            onTapCancel: _releaseHold,
            child: AnimatedBuilder(
              animation: _hold,
              builder: (context, _) {
                return SizedBox(
                  width: 116,
                  height: 116,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox.expand(
                        child: CircularProgressIndicator(
                          value: _hold.value,
                          strokeWidth: 4,
                          backgroundColor: colors.surface,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colors.signal,
                          ),
                        ),
                      ),
                      Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          color: colors.signal,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.flag_rounded,
                          color: colors.background,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _label,
            textAlign: TextAlign.center,
            style: TextStyle(color: _labelColor, fontSize: 13),
          ),
        ],
      ),
    );
  }

  String get _label => switch (_status) {
    _RoundStatus.idle => 'Tartsd nyomva',
    _RoundStatus.waiting => 'Küldve',
    _RoundStatus.confirmed => 'Megkerülve',
    _RoundStatus.failed => 'Nincs kapcsolat',
  };

  Color get _labelColor => switch (_status) {
    _RoundStatus.confirmed => widget.colors.signal,
    _RoundStatus.failed => widget.colors.critical,
    _ => widget.colors.textSecondary,
  };
}

// Ambient: statikus, tompított gomb, accent és interakció nélkül (OLED +
// energia).
class _AmbientRoundButton extends StatelessWidget {
  const _AmbientRoundButton({required this.colors});

  final WatchColors colors;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 92,
        height: 92,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: colors.textSecondary, width: 2),
        ),
        child: Icon(Icons.flag_outlined, color: colors.textSecondary, size: 40),
      ),
    );
  }
}
