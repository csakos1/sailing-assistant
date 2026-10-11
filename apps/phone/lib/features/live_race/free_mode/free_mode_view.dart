import 'dart:async';

import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/app/true_time.dart';
import 'package:phone/features/live_race/free_mode/free_mode_grid.dart';
import 'package:phone/features/live_race/free_mode/free_mode_link.dart';
import 'package:phone/features/live_race/free_mode/free_mode_strip.dart';
import 'package:phone/features/live_race/widgets/warning_banner.dart';
import 'package:phone/features/safety_map/safety_map_screen.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:phone/providers/active_warnings_provider.dart';
import 'package:phone/providers/connection_status_provider.dart';
import 'package:phone/providers/engine_service_error_provider.dart';
import 'package:phone/providers/engine_session_provider.dart';
import 'package:phone/providers/engine_session_state.dart';
import 'package:phone/providers/gps_time_reading_provider.dart';
import 'package:phone/providers/race_snapshot_provider.dart';
import 'package:phone/providers/tick_provider.dart';

/// A Műszerek fül szabad módja (34a, ADR 0056 D3, U3): verseny nélkül, vagy
/// amíg az engine nem versenyez (Cél után, rajt előtt az U4-ig, leállítva).
///
/// Az engine pillanatképéből olvas; az állapotot a [freeModeLinkOf] adja.
/// A mai 1c elemei közül a szolgáltatás-hibasor, a warning-szalag (benne a
/// sekély-víz riasztás), a kritikus warning miatti tompítás, az ELAVULT
/// chip és a nem szinkronizált idő jele itt is megmarad (`phone-ui-v1.md`
/// §11).
class FreeModeView extends ConsumerWidget {
  /// A szabad mód.
  const FreeModeView({super.key});

  // Megszakadt kapcsolatnál az utolsó értékek ennyire tompulnak (34a-3).
  static const double _lostOpacity = 0.42;

  // Kritikus warningnál a rács tompítása, mint az 1c-n (ADR 0014 D6).
  static const double _criticalOpacity = 0.4;

  // Ennél régebbi adat kapcsolódva is elavult (ADR 0042 D12, mint az 1c).
  static const Duration _staleAfter = Duration(seconds: 5);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Az `AppLocalizations` a `MaterialApp` alatt mindig jelen van.
    final l10n = AppLocalizations.of(context)!;
    final session = ref.watch(engineSessionProvider);
    final snapshot = ref.watch(raceSnapshotProvider);
    final tick = ref.watch(tickProvider).valueOrNull;
    final gpsTime =
        ref.watch(gpsTimeReadingProvider).valueOrNull ??
        const TrueTimeReading(utc: null, source: TrueTimeSource.none);
    // A gateway-kapcsolat warningját a csík már mutatja (pont + szöveg),
    // ezért a szabad mód kihagyja (U3 döntés); a többi warning marad.
    final warnings = ref
        .watch(activeWarningsProvider)
        .where((warning) => warning is! GatewayDisconnected)
        .toList();
    final serviceError = ref.watch(engineServiceErrorProvider);

    final boat = snapshot?.boatState;
    // Esemény nélküli pillanatkép a seedelt hajó-állapotot hordozza, aminek
    // az ideje az engine indulása, nem egy valódi adaté.
    final lastDataAt = (snapshot == null || snapshot.eventCount == 0)
        ? null
        : snapshot.boatState.lastUpdate;
    final link = freeModeLinkOf(
      session: session,
      connection: ref.watch(connectionStatusProvider),
      lastDataAt: lastDataAt,
      now: tick,
    );
    final hasValues = link is FreeModeLive || link is FreeModeLost;
    final isStale =
        link is FreeModeLive &&
        lastDataAt != null &&
        tick != null &&
        tick.difference(lastDataAt) > _staleAfter;
    final hasCriticalWarning = warnings.any(
      (warning) => warning.severity == WarningSeverity.critical,
    );
    // A kettő közül a kisebbik nyer: a kritikus warning tompítása a
    // nagyobb, ezért elég előre venni.
    final gridOpacity = hasCriticalWarning
        ? _criticalOpacity
        : link is FreeModeLost
        ? _lostOpacity
        : 1.0;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            FreeModeStrip(
              link: link,
              trueTime: gpsTime,
              isStale: isStale,
              onOpenMap: () => unawaited(
                Navigator.of(context).push<void>(
                  MaterialPageRoute(builder: (_) => const SafetyMapScreen()),
                ),
              ),
              onStop: session is EngineStopped
                  ? null
                  : () => unawaited(_confirmStop(context, ref, l10n)),
            ),
            // A hibasor a warningok FÖLÖTT, mint az 1c-n (ADR 0042 D12).
            if (serviceError != null)
              WarningStrip(
                message: l10n.liveServiceError(serviceError),
                severity: WarningSeverity.critical,
                background: Theme.of(context).colorScheme.errorContainer,
                icon: Icons.error_outline,
              ),
            WarningBanner(warnings: warnings),
            Expanded(
              child: Opacity(
                opacity: gridOpacity,
                child: FreeModeGrid(
                  hasValues: hasValues,
                  speedThroughWater: boat?.speedThroughWater,
                  speedOverGround: boat?.speedOverGround,
                  targetSpeedKnots: snapshot?.targetSpeedKnots,
                  vmgKnots: snapshot?.vmgKnots,
                  targetVmgKnots: snapshot?.targetVmgKnots,
                  vmgSteerCorrection: snapshot?.vmgSteerCorrection,
                  trueWindAngle: snapshot?.wind?.trueAngleWater,
                  trueWindSpeed: snapshot?.wind?.trueSpeedWater,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // A „Leállítás": megerősítés után leállítja a sessiont; a keresés a
  // következő előtérbe kerüléskor indul újra (ADR 0054 D5, U3 döntés).
  Future<void> _confirmStop(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    // A notifiert a dialógus előtt fogjuk el: közben a fül tartalma az 1c-re
    // válthat (az engine rajtja), és a megerősítés akkor is számít. A
    // provider keep-alive, így a notifier a widget nélkül is érvényes.
    final session = ref.read(engineSessionProvider.notifier);
    final confirmed = await showForetackDialog<bool>(
      context: context,
      title: l10n.instrumentsStopTitle,
      message: l10n.instrumentsStopMessage,
      actions: [
        ForetackDialogAction(label: l10n.liveStopCancel, value: false),
        ForetackDialogAction(
          label: l10n.liveStopConfirm,
          value: true,
          isDestructive: true,
        ),
      ],
    );
    if (confirmed != true) return;
    session.stopManually();
  }
}
