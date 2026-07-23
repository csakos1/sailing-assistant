import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:phone/providers/active_race_provider.dart';
import 'package:phone/widgets/mark_pin.dart';

/// Az aktív verseny pályájának bójái az élő biztonsági térképen
/// (ADR 0037 D10, D14).
///
/// **A megosztott `MarkPin`-nel rajzol**, ugyanazzal a számozott
/// korong-jellel, amit a post-race track-térkép használ. Így a két nézet
/// ugyanazt a vizuális nyelvet beszéli, és a pálya-bója ránézésre
/// elkülönül a kardinálistól: számozott korong versus bójajel topjellel.
/// Második pin-widget szándékosan nem készül.
///
/// **Az aktív bója kiemelve.** A kiemelés az `activeMarkIndex`-en megy,
/// nem a `Mark` egyenlőségén: két azonos nevű és pozíciójú bója egy
/// pályán ritka, de ha előfordulna, az egyenlőség mindkettőt kiemelné.
/// Az index a domain saját fogalma, és a `finished` állapotban
/// tartományon kívülre mutat — ekkor egyik bója sem kiemelt, ami helyes.
///
/// Aktív verseny nélkül semmit nem rajzol. A képernyő ilyenkor is
/// használható: a kardinálisok, a hajó és a vektor a versenytől
/// függetlenül látszanak.
class RaceMarkLayer extends ConsumerWidget {
  /// Az aktív verseny bóják rétege.
  const RaceMarkLayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final race = ref.watch(activeRaceProvider);
    if (race == null) return const SizedBox.shrink();
    return MarkerLayer(
      markers: [
        for (final (index, mark) in race.marks.indexed)
          Marker(
            point: LatLng(mark.position.latitude, mark.position.longitude),
            width: MarkPin.labelledWidth,
            height: MarkPin.labelledHeight,
            child: MarkPin(
              label: '${mark.sequence}',
              name: mark.name,
              isActive: index == race.activeMarkIndex,
            ),
          ),
      ],
    );
  }
}
