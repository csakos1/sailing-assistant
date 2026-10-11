import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/app/screen_wake_lock.dart';
import 'package:phone/features/live_race/free_mode/free_mode_view.dart';
import 'package:phone/features/live_race/instruments_content.dart';
import 'package:phone/features/live_race/instruments_content_provider.dart';
import 'package:phone/features/live_race/race_view/race_instruments_view.dart';
import 'package:phone/providers/screen_wake_lock_provider.dart';

/// A héj Műszerek füle (ADR 0056 D2, D3): az engine állapota szerint a
/// szabad mód ([FreeModeView], 34a), a rajt előtti nézet (34b) vagy a
/// verseny (34c, [RaceInstrumentsView]). A tartalmat az
/// [instrumentsContentOf] választja.
///
/// `ConsumerStatefulWidget`, mert a portrait-lockot és a kijelző ébren
/// tartását a fül mount/unmount életciklusához kötjük: a műszer-oszlop és
/// a sín landscape-ben rosszul reflow-ol. A kijelző rajt előtt és
/// versenyen ég, szabad módban a rendszer szerint alszik el (felhasználói
/// döntés, U4); az óra-adatot ettől függetlenül a háttér-engine küldi.
class LiveRaceScreen extends ConsumerStatefulWidget {
  /// A Műszerek fül.
  const LiveRaceScreen({super.key});

  @override
  ConsumerState<LiveRaceScreen> createState() => _LiveRaceScreenState();
}

class _LiveRaceScreenState extends ConsumerState<LiveRaceScreen> {
  // A dispose-ban már nem olvasunk providert, ezért az initState-ben fogjuk
  // el.
  late final ScreenWakeLock _wakeLock;

  // A wakelock állapota itt, egy helyen: két verseny-nézet cseréjekor (új
  // kulcs) az új `initState`-je a régi `dispose`-a ELŐTT futna, így egy
  // nézethez kötött wakelock a végén kikapcsolva maradna.
  bool _isScreenKeptOn = false;

  @override
  void initState() {
    super.initState();
    _wakeLock = ref.read(screenWakeLockProvider);
    unawaited(
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
    );
    ref.listenManual<InstrumentsContent>(
      instrumentsContentProvider,
      (_, content) => _keepScreenOn(content is! InstrumentsFreeMode),
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    if (_isScreenKeptOn) unawaited(_wakeLock.disable());
    unawaited(SystemChrome.setPreferredOrientations(DeviceOrientation.values));
    super.dispose();
  }

  void _keepScreenOn(bool isOn) {
    if (isOn == _isScreenKeptOn) return;
    _isScreenKeptOn = isOn;
    unawaited(isOn ? _wakeLock.enable() : _wakeLock.disable());
  }

  @override
  Widget build(BuildContext context) {
    // A kulcs a verseny id-je: egy váltás után a nézet (a nyitott lista)
    // tisztán indul, a rajt viszont (34b → 34c, ugyanaz az id) nem építi
    // újra.
    return switch (ref.watch(instrumentsContentProvider)) {
      InstrumentsFreeMode() => const FreeModeView(),
      InstrumentsPreStart(:final race) => RaceInstrumentsView(
        key: ValueKey(race.id),
        race: race,
        isPreStart: true,
      ),
      InstrumentsRacing(:final race) => RaceInstrumentsView(
        key: ValueKey(race.id),
        race: race,
        isPreStart: false,
      ),
    };
  }
}
