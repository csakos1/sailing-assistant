import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/features/live_race/live_race_screen.dart';
import 'package:phone/features/race_list/race_list_entries_provider.dart';
import 'package:phone/features/race_list/race_list_screen.dart';
import 'package:phone/features/race_log/race_log_screen.dart';
import 'package:phone/features/shell/day_race_provider.dart';
import 'package:phone/features/shell/instruments_tab_status_provider.dart';
import 'package:phone/features/shell/shell_tab.dart';
import 'package:phone/features/shell/shell_tab_provider.dart';
import 'package:phone/features/shell/widgets/shell_navigation_bar.dart';
import 'package:phone/providers/pending_race_deletions_provider.dart';
import 'package:phone/providers/race_start_signal_provider.dart';

/// Az app háromfüles héja (ADR 0056 D2, `phone-ui-v1.md` §2).
///
/// A Versenyek és a Versenynapló egy `IndexedStack`-ben él, így a
/// görgetésük és a kiválasztott év váltáskor megmarad (a napló az első
/// megnyitásától). A Műszerek csak
/// látható fülként épül fel: a képernyő bekapcsolja a kijelző-wakelockot és
/// a portrait-zárat (mount / unmount), ezek így csak akkor élnek, amikor a
/// fül látszik. A push-olt képernyők a héj fölé, sáv nélkül nyílnak.
///
/// Kívülről csak a rajt vált fület (a [raceStartSignalProvider] jelzése:
/// kézi rajt, az engine rajtjának átvétele, vagy egy futó verseny
/// induláskori visszatöltése): a héj a Műszerekre vált, és ha az app
/// előtérben van, a push-olt képernyőket bezárja, kivéve amelyik nem
/// engedi (`PopScope`). A vissza-gomb a Versenyekre lép, onnan
/// kilép. Háttérbe kerüléskor a függő (visszavonható) törlések elmaradnak.
class PhoneShell extends ConsumerStatefulWidget {
  /// Héj a három fül tartalmával; a tesztek egyszerű helyettesítőket
  /// adhatnak.
  const PhoneShell({
    this.races = const RaceListScreen(),
    this.instruments = const LiveRaceScreen(),
    this.log = const RaceLogScreen(),
    super.key,
  });

  /// A Versenyek fül tartalma.
  final Widget races;

  /// A Műszerek fül tartalma; csak kiválasztva épül fel.
  final Widget instruments;

  /// A Versenynapló fül tartalma; az első megnyitásakor épül fel, utána
  /// életben marad.
  final Widget log;

  @override
  ConsumerState<PhoneShell> createState() => _PhoneShellState();
}

class _PhoneShellState extends ConsumerState<PhoneShell> {
  late final AppLifecycleListener _lifecycle;

  // A napló az első megnyitásáig nem épül fel: a stat-csíkja egy hideg
  // indításnál lassú DB-olvasást indít, ami ne az app indulását terhelje.
  bool _hasOpenedLog = false;

  @override
  void initState() {
    super.initState();
    // A nap versenye és a lajstrom „ma"-ja nem időzít; előtérbe
    // kerüléskor számol újra (a rajtidő-címke és a mai kiemelés egy
    // lejárt ablak vagy egy új nap után itt frissül).
    _lifecycle = AppLifecycleListener(
      onResume: () => ref
        ..invalidate(instrumentsRaceChoiceProvider)
        ..invalidate(dayRaceProvider)
        ..invalidate(raceListEntriesProvider),
      onHide: _cancelPendingDeletions,
    );
  }

  // Háttérbe kerüléskor a függő törlések elmaradnak (ADR 0056 D6): a
  // biztonságos irány, a verseny visszajön. A VISSZAVONÁS-snackbar ilyenkor
  // már nem ígérhet semmit, ezért eltűnik. Az értesítési sáv (`inactive`)
  // nem számít háttérnek.
  void _cancelPendingDeletions() {
    final hadPending = ref
        .read(pendingRaceDeletionsProvider.notifier)
        .cancelAll();
    if (hadPending && mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  ShellTabNotifier get _tabs => ref.read(shellTabProvider.notifier);

  void _onRaceStarted(RaceStartSignal? _, RaceStartSignal? signal) {
    if (signal == null) return;
    _tabs.tab = ShellTab.instruments;
    // Háttérben (az értesítési sáv `inactive`-ja is ide számít) nem zárunk
    // be képernyőt, a fül-váltás elég. A `null` az első életciklus-jelzés
    // előtti állapot (induláskor): előtér.
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if (lifecycle != null && lifecycle != AppLifecycleState.resumed) return;
    // Csak azt zárjuk be, ami engedi: egy `PopScope`-pal védett képernyő
    // (pl. a helyreállító kódok) a helyén marad.
    Navigator.of(context).popUntil(
      (route) =>
          route.isFirst || route.popDisposition != RoutePopDisposition.pop,
    );
  }

  // Minden fül-választás erre fut; kívülről csak a Műszerekre váltunk,
  // ezért a napló jelzőjét elég itt állítani.
  void _selectTab(ShellTab selected) {
    if (selected == ShellTab.log) _hasOpenedLog = true;
    _tabs.tab = selected;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<RaceStartSignal?>(raceStartSignalProvider, _onRaceStarted);
    final tab = ref.watch(shellTabProvider);
    final status = ref.watch(instrumentsTabStatusProvider);
    return PopScope(
      canPop: tab == ShellTab.races,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _selectTab(ShellTab.races);
      },
      child: Scaffold(
        // A rejtett fülek animációi futnak tovább (IndexedStack); ma egyik
        // fül sem tart állandó animációt.
        body: IndexedStack(
          index: tab.index,
          children: [
            widget.races,
            if (tab == ShellTab.instruments)
              widget.instruments
            else
              const SizedBox.shrink(),
            if (_hasOpenedLog || tab == ShellTab.log)
              widget.log
            else
              const SizedBox.shrink(),
          ],
        ),
        bottomNavigationBar: ShellNavigationBar(
          selected: tab,
          status: status,
          onSelected: _selectTab,
        ),
      ),
    );
  }
}
