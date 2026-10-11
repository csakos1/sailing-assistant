import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/features/live_race/free_mode/free_mode_link.dart';
import 'package:phone/providers/connection_status_provider.dart';
import 'package:phone/providers/engine_session_provider.dart';
import 'package:phone/providers/race_snapshot_provider.dart';
import 'package:phone/providers/tick_provider.dart';

/// A Műszerek csíkjának kapcsolat-állapota mindhárom tartalomhoz.
///
/// A `link` a [freeModeLinkOf] szerint (ADR 0056 U3), az `isStale` igaz, ha
/// kapcsolódva vagyunk, de az utolsó adat 5 mp-nél régebbi (ADR 0042
/// D12).
typedef InstrumentsLinkState = ({FreeModeLink link, bool isStale});

// Ennél régebbi adat kapcsolódva is elavult (ADR 0042 D12).
const Duration _staleAfter = Duration(seconds: 5);

/// A Műszerek fül közös kapcsolat-állapota (34a, 34b, 34c, ADR 0056 U4):
/// a rajt előtti és a versenyes csík ugyanazt a szabályt kapja, mint a
/// szabad mód, így újrakapcsolódás alatt egyik sem villog.
final AutoDisposeProvider<InstrumentsLinkState> instrumentsLinkProvider =
    Provider.autoDispose<InstrumentsLinkState>((ref) {
      final snapshot = ref.watch(raceSnapshotProvider);
      final tick = ref.watch(tickProvider).valueOrNull;
      // Esemény nélküli pillanatkép a seedelt hajó-állapotot hordozza, aminek
      // az ideje az engine indulása, nem egy valódi adaté.
      final lastDataAt = (snapshot == null || snapshot.eventCount == 0)
          ? null
          : snapshot.boatState.lastUpdate;
      final link = freeModeLinkOf(
        session: ref.watch(engineSessionProvider),
        connection: ref.watch(connectionStatusProvider),
        lastDataAt: lastDataAt,
        now: tick,
      );
      final isStale =
          link is FreeModeLive &&
          lastDataAt != null &&
          tick != null &&
          tick.difference(lastDataAt) > _staleAfter;
      return (link: link, isStale: isStale);
    });
