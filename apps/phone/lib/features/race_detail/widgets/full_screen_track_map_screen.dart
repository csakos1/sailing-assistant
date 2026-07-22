import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:phone/features/race_detail/track_point.dart';
import 'package:phone/features/race_detail/widgets/track_map.dart';
import 'package:phone/features/race_detail/widgets/track_speed_legend.dart';
import 'package:phone/l10n/app_localizations.dart';

/// A post-race track teljes képernyős, nagyítható nézete (ADR 0036 F1-D3).
///
/// A kártyáról koppintásra nyílik, `MaterialPageRoute`-tal — nem dialógus és
/// nem bottom sheet, mert teljes magasság és rendszer-visszalépés kell. A
/// térkép itt kitölti a helyet, fogadja a húzást és a zoomot, és kiírja a
/// bóják nevét; a rotáció viszont tiltott (F1-D4): elforgatott térképen a
/// vitorlázó elveszti az észak-referenciát.
///
/// A tartalom-oszlop (térkép + legenda) már most `RepaintBoundary`-ben ül
/// (F1-D7). Az F1 ezt nem használja — ez az F2 PNG-exportjának a
/// capture-pontja, és utólag beszúrni kockázatosabb lenne (a `GlobalKey`
/// elhelyezése és a layout-hatás együtt változna), mint előre kijelölni.
class FullScreenTrackMapScreen extends StatelessWidget {
  /// A [raceName] az AppBar címe; a [points] és a [marks] ugyanaz az adat,
  /// amit a kártya is kapott — a képernyő nem olvas újra semmit.
  const FullScreenTrackMapScreen({
    required this.raceName,
    required this.points,
    required this.marks,
    super.key,
  });

  /// A verseny neve: ez az AppBar címe (F1-D3). Skalár, nem a teljes `Race`
  /// entitás — a képernyőnek a státuszra és a többi mezőre nincs szüksége.
  final String raceName;

  /// A vitorlázott track pontjai időrendben, sebességgel annotálva.
  final List<TrackPoint> points;

  /// A pálya bójái a térkép-markerekhez.
  final List<Mark> marks;

  @override
  Widget build(BuildContext context) {
    // A `!` biztonságos: a MaterialApp a `localizationsDelegates`-en
    // keresztül mindig szolgáltat AppLocalizations-t a fa alá.
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(raceName)),
      body: SafeArea(
        child: RepaintBoundary(
          child: Column(
            children: [
              Expanded(
                child: TrackMap(
                  points: points,
                  marks: marks,
                  emptyLabel: l10n.detailTrackEmpty,
                  isInteractive: true,
                  height: null,
                  showMarkLabels: true,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: TrackSpeedLegend(
                  title: l10n.detailTrackLegendTitle,
                  unknownLabel: l10n.detailTrackLegendUnknown,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
