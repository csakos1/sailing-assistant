import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:phone/features/race_detail/export/track_export_content.dart';
import 'package:phone/features/race_detail/export/track_export_error_message.dart';
import 'package:phone/features/race_detail/export/track_exporter.dart';
import 'package:phone/features/race_detail/track_point.dart';
import 'package:phone/features/race_detail/widgets/track_map.dart';
import 'package:phone/features/race_detail/widgets/track_speed_legend.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:shared/shared.dart';

/// A post-race track teljes képernyős, nagyítható nézete (ADR 0036 F1-D3),
/// és innen indul a megosztható PNG-export is (F2-D9).
///
/// A kártyáról koppintásra nyílik, `MaterialPageRoute`-tal — nem dialógus és
/// nem bottom sheet, mert teljes magasság és rendszer-visszalépés kell. A
/// térkép itt kitölti a helyet, fogadja a húzást és a zoomot, és kiírja a
/// bóják nevét; a rotáció viszont tiltott (F1-D4): elforgatott térképen a
/// vitorlázó elveszti az észak-referenciát.
///
/// A tartalom-oszlop (térkép + legenda) `RepaintBoundary`-ben ül (F1-D7):
/// ez az export capture-pontja, ezért van rajta `GlobalKey`. Az export
/// WYSIWYG — azt a kivágást és nagyítást örökli, amit a felhasználó éppen
/// lát (F2-D9) —, és ezért állapotos a képernyő: a capture-kulcsot és a
/// hibás csempék számát is a `State` őrzi.
class FullScreenTrackMapScreen extends StatefulWidget {
  /// A [raceName] az AppBar címe és a kép fejlécének első sora; a
  /// [raceStartedAt] a fejléc dátuma; a [points], a [marks] és a [stats]
  /// ugyanaz az adat, amit a kártya is kapott — a képernyő nem olvas újra
  /// semmit (F1-D3, A1-D9).
  const FullScreenTrackMapScreen({
    required this.raceName,
    required this.raceStartedAt,
    required this.points,
    required this.marks,
    required this.stats,
    super.key,
  });

  /// A verseny neve. Skalár, nem a teljes `Race` entitás — a képernyőnek a
  /// státuszra és a többi mezőre nincs szüksége (ISP).
  final String raceName;

  /// A verseny startja a kép fejlécének dátumához; `null` esetén hiányjel.
  final DateTime? raceStartedAt;

  /// A vitorlázott track pontjai időrendben, sebességgel annotálva.
  final List<TrackPoint> points;

  /// A pálya bójái a térkép-markerekhez.
  final List<Mark> marks;

  /// A track összesítői a kép statisztika-sorához (max / átlag / táv).
  final TrackStats stats;

  @override
  State<FullScreenTrackMapScreen> createState() =>
      _FullScreenTrackMapScreenState();
}

class _FullScreenTrackMapScreenState extends State<FullScreenTrackMapScreen> {
  /// Az export capture-pontja: ezen a boundary-n áll a térkép + a legenda.
  final GlobalKey _boundaryKey = GlobalKey();

  /// A sikertelen csempe-betöltések száma a nézet megnyitása óta (F2-D13).
  ///
  /// Szándékosan NEM `setState`-tel nő: a szám sehol nem jelenik meg, a
  /// callback viszont festés közben érkezik — egy pásztázás alatt tucatnyi
  /// fölösleges újraépítést okozna. És szándékosan nem nullázódik: a
  /// `flutter_map` alapértelmezett `EvictErrorTileStrategy.none`-ja bent
  /// hagyja a hibás csempét a cache-ben, tehát a fehér folt magától nem
  /// gyógyul meg.
  int _failedTileCount = 0;

  /// Fut-e éppen export. A gomb ilyenkor letiltott: a dupla koppintás
  /// egyébként két megosztó felületet nyitna ugyanarra a képre.
  bool _isExporting = false;

  void _countFailedTile() => _failedTileCount++;

  /// Rövid visszajelzés a képernyő alján — a hibaüzenetek egyetlen csatornája.
  void _showMessage(String message) {
    final snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// Megerősítést kér, ha a térkép-háttér hiányos (F2-D13).
  ///
  /// A néma szürke folt nem elfogadható kimenet, a megszakítás nélküli
  /// figyelmeztetés pedig későn érkezne: a kép addigra már elment.
  Future<bool> _confirmIncompleteTiles(AppLocalizations l10n) async {
    final answer = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.trackExportTileWarningTitle),
        content: Text(l10n.trackExportTileWarningBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.trackExportTileWarningCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.trackExportTileWarningConfirm),
          ),
        ],
      ),
    );
    // A dialógus a hátterére koppintva is eltűnhet: az nem beleegyezés.
    return answer ?? false;
  }

  Future<void> _export() async {
    // A lokalizációt az első await ELŐTT olvassuk ki, hogy utána ne kelljen
    // a contexthez nyúlni.
    final l10n = AppLocalizations.of(context)!;
    if (_failedTileCount > 0) {
      final shouldExport = await _confirmIncompleteTiles(l10n);
      if (!shouldExport || !mounted) return;
    }
    setState(() => _isExporting = true);
    try {
      // A `toImage` `assert(!debugNeedsPaint)`-et állít, a gomb letiltása
      // pedig épp most piszkította be a fát: meg kell várni a keretet.
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      final boundary = _boundaryKey.currentContext?.findRenderObject();
      if (boundary is! RenderRepaintBoundary) {
        // Elvben lehetetlen (a kulcs a saját fánk boundary-jén ül), de a
        // vízparton egy olvasható üzenet többet ér, mint egy kivétel.
        _showMessage(l10n.trackExportErrorCapture);
        return;
      }
      final result = await exportAndShareTrackImage(
        boundary: boundary,
        content: TrackExportContent.fromTrackStats(
          raceName: widget.raceName,
          startedAt: widget.raceStartedAt,
          stats: widget.stats,
          l10n: l10n,
        ),
        raceName: widget.raceName,
        startedAt: widget.raceStartedAt,
      );
      if (!mounted) return;
      // A siker néma: a megosztó felület maga a visszajelzés, a `dismissed`
      // státusz pedig a felhasználó döntése, nem hiba (3.65).
      if (result case Err(:final error)) {
        _showMessage(trackExportErrorMessage(error, l10n));
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // A `!` biztonságos: a MaterialApp a `localizationsDelegates`-en
    // keresztül mindig szolgáltat AppLocalizations-t a fa alá.
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.raceName),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: l10n.trackExportAction,
            onPressed: _isExporting ? null : _export,
          ),
        ],
      ),
      body: SafeArea(
        child: RepaintBoundary(
          key: _boundaryKey,
          child: Column(
            children: [
              Expanded(
                child: TrackMap(
                  points: widget.points,
                  marks: widget.marks,
                  emptyLabel: l10n.detailTrackEmpty,
                  isInteractive: true,
                  height: null,
                  showMarkLabels: true,
                  onTileLoadError: _countFailedTile,
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
