import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:watch/rotary/rotary_scroll_provider.dart';
import 'package:watch/screens/next_mark_view.dart';
import 'package:watch/screens/speed_view.dart';
import 'package:watch/theme/watch_colors.dart';
import 'package:watch/watch_sync/gps_clock_reading.dart';
import 'package:watch/watch_sync/race_ongoing_activity.dart';
import 'package:watch/watch_sync/watch_clock_provider.dart';
import 'package:watch/widgets/confidence_arc.dart';
import 'package:watch/widgets/watch_trust.dart';

/// A két verseny-nézet (A↔B) háza: fix GPS-idő fejléc, vízszintes `PageView`
/// (alapnézet B), és a perem-forgatás lap-navigációja (ADR 0015 Addendum). A
/// GPS-idő a `watchClockProvider`-ből ketyeg; az értékeket a két nézet
/// rendereli. Az ambient-tompítást a hívó adja az [ambient] zászlóval (a
/// `wear_plus` `AmbientMode`-ból), így ez a widget natív-mentes és tesztelhető.
///
/// A predikció-konfidencia ívét (ADR 0023 D7, jobb-perem revízió) is a ház
/// rajzolja: a fizikai kerek lap JOBB peremére, a teljes képernyőt kitöltő
/// háttér-rétegben — így független a fejléc/lap-pötty insetektől, és minden
/// óra-méreten a peremen ül. Csak a B (köv. bója) lapon látszik.
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
  // Alapnézet: B (köv. bója) — a headline feature. Lapok: 0 = A, 1 = B.
  static const _markPage = 1;

  late final PageController _controller;
  late final StreamSubscription<int> _rotarySteps;
  late final RaceOngoingActivity _ongoing;
  int _page = _markPage;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: _markPage);
    // A perem nyers deltáit lap-lépésekké fűzzük (4a), és minden lépésre
    // lapozunk; a közvetlen stream-feliratkozás (nem ref.listen) elkerüli az
    // AsyncValue de-duplikációját, hogy két azonos lépés se vesszen el.
    final deltas = ref.read(rotaryScrollSourceProvider)();
    _rotarySteps = rotaryPageSteps(deltas).listen(_stepBy);
    // ADR 0019: a kijelző mountjakor indul a verseny Ongoing Activity (a
    // számlapra-esés / Timeout #2 ellen), a dispose-ban áll le — a telefon
    // ScreenWakeLock-mintájának óra-oldali, láthatósági párja. Az instance-t
    // itt fogjuk el, mert a dispose-ban a ref már nem biztonságos.
    _ongoing = ref.read(raceOngoingActivityProvider);
    unawaited(_ongoing.start());
  }

  @override
  void dispose() {
    unawaited(_ongoing.stop());
    _rotarySteps.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _stepBy(int step) {
    final target = (_page + step).clamp(0, _markPage);
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
                ],
              ),
            ),
            if (!widget.ambient)
              _PageDots(active: _page, colors: widget.colors),
          ],
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
  const _PageDots({required this.active, required this.colors});

  final int active;
  final WatchColors colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var page = 0; page <= 1; page++)
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
