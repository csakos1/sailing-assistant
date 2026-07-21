import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:watch/rotary/rotary_scroll_provider.dart';
import 'package:watch/screens/confidence_haptic_edge.dart';
import 'package:watch/screens/depth_alert_edge.dart';
import 'package:watch/screens/depth_alert_overlay.dart';
import 'package:watch/screens/next_mark_view.dart';
import 'package:watch/screens/round_mark_view.dart';
import 'package:watch/screens/speed_view.dart';
import 'package:watch/theme/watch_colors.dart';
import 'package:watch/watch_sync/depth_alert_vibrator.dart';
import 'package:watch/watch_sync/gps_clock_reading.dart';
import 'package:watch/watch_sync/race_ongoing_activity.dart';
import 'package:watch/watch_sync/round_mark_sender.dart';
import 'package:watch/watch_sync/watch_clock_provider.dart';
import 'package:watch/widgets/confidence_arc.dart';
import 'package:watch/widgets/watch_trust.dart';

/// A három verseny-nézet (A↔B↔C) háza: fix GPS-idő fejléc, vízszintes `PageView`
/// (alapnézet B), és a perem-forgatás lap-navigációja (ADR 0015 Addendum). A
/// GPS-idő a `watchClockProvider`-ből ketyeg; az értékeket a két nézet
/// rendereli. Az ambient-tompítást a hívó adja az [ambient] zászlóval (a
/// `wear_plus` `AmbientMode`-ból), így ez a widget natív-mentes és tesztelhető.
///
/// A predikció-konfidencia ívét (ADR 0023 D7, jobb-perem revízió) is a ház
/// rajzolja: a fizikai kerek lap JOBB peremére, a teljes képernyőt kitöltő
/// háttér-rétegben — így független a fejléc/lap-pötty insetektől, és minden
/// óra-méreten a peremen ül. Csak a B (köv. bója) lapon látszik.
///
/// A sekély-víz riasztás (ADR 0031) mindezek fölé kerül: teljes-képernyős
/// overlay, ami a lapozást is elnyeli, plusz 1,5 s natív rezgés a
/// `depthBuzzCounter` változó élén. A rezgés a `DepthAlertVibrator`
/// varraton megy, mert a `HapticFeedback` nem tud hosszt/amplitúdót.
class RaceShell extends ConsumerStatefulWidget {
  /// Létrehozza a házat a megjelenítendő [payload]-dal.
  const RaceShell({
    required this.payload,
    required this.colors,
    required this.ambient,
    super.key,
  });

  /// A megjelenítendő, már kiszámolt értékek.
  final WatchPayload payload;

  /// A téma szín-tokenjei.
  final WatchColors colors;

  /// Ambient mód: csak a hero + idő, accent nélkül.
  final bool ambient;

  @override
  ConsumerState<RaceShell> createState() => _RaceShellState();
}

class _RaceShellState extends ConsumerState<RaceShell> {
  // Alapnézet: B (köv. bója) — a headline feature. Lapok: 0 = A, 1 = B, 2 = C.
  static const _markPage = 1;
  static const _roundPage = 2;

  late final PageController _controller;
  late final StreamSubscription<int> _rotarySteps;
  late final RaceOngoingActivity _ongoing;
  late final DepthAlertVibrator _vibrator;
  int _page = _markPage;

  // A sekély-víz overlay bezárásakor rögzített számláló-érték; null, ha még
  // egyetlen riasztást sem zártak be (lásd `depth_alert_edge.dart`).
  int? _dismissedAtCounter;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: _markPage);
    // A perem nyers deltáit lap-lépésekké fűzzük (4a), és minden lépésre
    // lapozunk; a közvetlen stream-feliratkozás (nem ref.listen) elkerüli az
    // AsyncValue de-duplikációját, hogy két azonos lépés se vesszen el.
    final deltas = ref.read(rotaryScrollSourceProvider)();
    // A perem-irány megfordítva: a CW-forgatás a túloldali lap felé
    // lapozzon (a korábbi leképezés fordított volt az elvárthoz képest).
    _rotarySteps = rotaryPageSteps(deltas).listen((step) => _stepBy(-step));
    // ADR 0019: a kijelző mountjakor indul a verseny Ongoing Activity (a
    // számlapra-esés / Timeout #2 ellen), a dispose-ban áll le — a telefon
    // ScreenWakeLock-mintájának óra-oldali, láthatósági párja. Az instance-t
    // itt fogjuk el, mert a dispose-ban a ref már nem biztonságos.
    _ongoing = ref.read(raceOngoingActivityProvider);
    unawaited(_ongoing.start());
    // A rezgés-varratot is itt fogjuk el: a didUpdateWidget forró úton fut,
    // ott ne kelljen provider-t olvasni.
    _vibrator = ref.read(depthAlertVibratorProvider);
  }

  @override
  void didUpdateWidget(RaceShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Konfidencia-high haptic: a shiftConfidence high-ra való felfutó élén
    // egyetlen határozott buzz. Az él-detektálás a debounce (újrafegyverkezik,
    // ha high alá esik); lapfüggetlen és ambientben is szól. Az induló payload
    // sosem buzzol (nincs korábbi érték: didUpdateWidget még nem futott).
    if (isRisingToHighConfidence(
      oldWidget.payload.shiftConfidence,
      widget.payload.shiftConfidence,
    )) {
      unawaited(HapticFeedback.heavyImpact());
    }
    // Sekély-víz riasztás (ADR 0031 D4): a depthBuzzCounter VÁLTOZÓ élén
    // 1,5 s erős natív rezgés. Lapfüggetlen és ambientben is szól.
    if (isRisingDepthBuzz(
      previousCounter: oldWidget.payload.depthBuzzCounter,
      currentCounter: widget.payload.depthBuzzCounter,
      currentDepthMeters: widget.payload.depthAlertMeters,
    )) {
      unawaited(_vibrator());
    }
  }

  @override
  void dispose() {
    unawaited(_ongoing.stop());
    _rotarySteps.cancel();
    _controller.dispose();
    super.dispose();
  }

  // A sekély-víz overlay láthatósága: a payload és a bezárt számláló-érték
  // együtt dönt (ADR 0031, `depth_alert_edge.dart`).
  bool get _isDepthAlertVisible => isDepthAlertVisible(
    depthAlertMeters: widget.payload.depthAlertMeters,
    depthBuzzCounter: widget.payload.depthBuzzCounter,
    dismissedAtCounter: _dismissedAtCounter,
  );

  void _dismissDepthAlert() {
    setState(() => _dismissedAtCounter = widget.payload.depthBuzzCounter);
  }

  void _stepBy(int step) {
    // A riasztás a perem-lapozást is elnyeli: alatta ne mozduljon el
    // észrevétlenül a nézet, amíg a kormányos a mélységet olvassa.
    if (_isDepthAlertVisible) {
      return;
    }
    final target = (_page + step).clamp(0, _roundPage);
    if (target != _page) {
      _controller.animateToPage(
        target,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final reading =
        ref.watch(watchClockProvider).valueOrNull ??
        const GpsClockReading.untrusted();

    // Konfidencia-ív (ADR 0023 D7, jobb-perem revízió): a fizikai kerek lap
    // JOBB peremén, a teljes képernyőt kitöltő háttér-rétegben — független a
    // fejléc/lap-pötty insetektől, ezért minden órán és ambientben is a valódi
    // peremen ül. Csak a B (köv. bója) lapon, és csak ha van predikció-
    // konfidencia (a SpeedView-nak nincs).
    final arc = _page == _markPage
        ? confidenceArc(widget.payload.shiftConfidence, widget.colors)
        : null;

    // Sekély-víz overlay (ADR 0031): a lap-pöttyök fölé is, teljes lapon.
    final depthAlertMeters = _isDepthAlertVisible
        ? widget.payload.depthAlertMeters
        : null;

    return Stack(
      children: [
        if (arc != null)
          Positioned.fill(
            child: ConfidenceArc(
              color: arc.color,
              fraction: arc.fraction,
              ambient: widget.ambient,
            ),
          ),
        Column(
          children: [
            _GpsTimeHeader(
              reading: reading,
              colors: widget.colors,
              ambient: widget.ambient,
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (page) => setState(() => _page = page),
                children: [
                  SpeedView(
                    payload: widget.payload,
                    colors: widget.colors,
                    ambient: widget.ambient,
                  ),
                  NextMarkView(
                    payload: widget.payload,
                    colors: widget.colors,
                    ambient: widget.ambient,
                  ),
                  RoundMarkView(
                    payload: widget.payload,
                    colors: widget.colors,
                    ambient: widget.ambient,
                    onSend: ref.read(roundMarkSenderProvider),
                  ),
                ],
              ),
            ),
            if (!widget.ambient)
              _PageDots(
                active: _page,
                count: _roundPage + 1,
                colors: widget.colors,
              ),
          ],
        ),
        if (depthAlertMeters != null)
          Positioned.fill(
            child: DepthAlertOverlay(
              depthMeters: depthAlertMeters,
              colors: widget.colors,
              ambient: widget.ambient,
              onDismiss: _dismissDepthAlert,
            ),
          ),
      ],
    );
  }
}

class _GpsTimeHeader extends StatelessWidget {
  const _GpsTimeHeader({
    required this.reading,
    required this.colors,
    required this.ambient,
  });

  final GpsClockReading reading;
  final WatchColors colors;
  final bool ambient;

  @override
  Widget build(BuildContext context) {
    // Ambientben nincs accent (OLED burn-in + energia): a pötty mindig tompa.
    final dotColor = (!ambient && reading.isTrusted)
        ? colors.signal
        : colors.textTertiary;
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            formatLocalClock(reading.displayUtc),
            style: TextStyle(
              color: ambient ? colors.textSecondary : colors.text,
              fontSize: 15,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({
    required this.active,
    required this.count,
    required this.colors,
  });

  final int active;
  final int count;
  final WatchColors colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var page = 0; page < count; page++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: page == active ? colors.text : colors.textTertiary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
