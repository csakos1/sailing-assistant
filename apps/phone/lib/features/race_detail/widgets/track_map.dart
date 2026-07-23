import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:phone/app/marine_colors.dart';
import 'package:phone/features/race_detail/track_point.dart';
import 'package:phone/widgets/map_attribution.dart';
import 'package:phone/widgets/mark_pin.dart';

/// A vitorlazott track + a palya bojai online OSM-terkep felett (ADR 0035 +
/// ADR 0034 Addendum 3/4). A track sebesseg szerint szinezett: szakaszonkenti
/// [Polyline]-ok, a szomszedos azonos-savu szakaszok run-merge-elve (A4-D4); a
/// szin a [colorForTrackSpeed] savjabol jon. A bojak szamozott [Marker]-ek; a
/// nezet a track (+ bojak) befoglalo-dobozara illeszt ([CameraFit.bounds]).
/// Pozicio nelkul az [emptyLabel] ures-allapotot mutat (A3-D5).
///
/// Ket megjelenesi modja van (ADR 0036 F1-D1), ugyanabbol a kodbol:
/// - **kartya** (default): fix magassag, lekerekitett doboz, gesztus-mentes,
///   hogy a szulo lista gorgeteset ne nyelje el;
/// - **nagy nezet**: `isInteractive: true`, `height: null`,
///   `showMarkLabels: true` -- a widget kitolti a helyet, nagyithato, es a
///   bojak neve is latszik. `height: null` eseten a hivonak KELL korlatos
///   magassagot adnia (pl. [Expanded]).
///
/// Allapotos, mert sajat [MapController]-t tart (ADR 0036 A2-D5): a viewport
/// meretvaltozasakor -- tipikusan eszkoz-forgataskor -- a kamerat ujra kell
/// illeszteni, amire a [MapOptions] maga nem kepes, mert a mezoi csak
/// inicializalaskor ervenyesulnek (A2-D2).
///
/// A widget kizarolag a presentation reteg: a [TrackPoint]/[Mark] primitiveken
/// kap adatot, es itt mappeli `LatLng`-re (a `flutter_map` tipusa).
class TrackMap extends StatefulWidget {
  /// A [points] track-vonalat (sebesseggel szinezve) es a [marks] bojakat
  /// rajzolja; ures pontlistanal az [emptyLabel] szoveget mutatja.
  const TrackMap({
    required this.points,
    required this.marks,
    required this.emptyLabel,
    this.isInteractive = false,
    this.height = _defaultHeight,
    this.showMarkLabels = false,
    this.onTileLoadError,
    super.key,
  });

  /// A vitorlazott track pontjai idorendben, sebesseggel annotalva.
  final List<TrackPoint> points;

  /// A palya bojai a terkep-markerekhez.
  final List<Mark> marks;

  /// Az ures-allapot szovege, ha nincs egyetlen track-pont sem.
  final String emptyLabel;

  /// Engedelyezi a huzast, a pinch-zoomot es a dupla-koppintasos zoomot
  /// (ADR 0036 F1-D4). A rotacio SOHA nincs engedelyezve: eszak-fent rogzitve.
  final bool isInteractive;

  /// A terkep fix magassaga; `null` eseten kitolti a rendelkezesre allo helyet,
  /// es a lekerekites is elmarad (nagy nezet).
  final double? height;

  /// Kiirja a bojak neveit a szamozott korong ala (ADR 0036 F1-D6). A
  /// kartyan kikapcsolva, mert ott a feliratok egymasra csusznanak.
  final bool showMarkLabels;

  /// Jelzes a hivonak, ha egy terkep-csempe betoltese elbukott.
  ///
  /// Szandekosan argumentum nelkuli, hogy a hivonak ne kelljen flutter_map-
  /// tipust importalnia: a csomag ebben a fajlban marad bezarva. Az export
  /// elotti tile-hiany figyelmeztetes (ADR 0036 F2-D13) ebbol szamol.
  final VoidCallback? onTileLoadError;

  static const double _defaultHeight = 220;
  static const double _radius = 10;

  /// A nagy nezeten engedelyezett gesztusok. A [InteractiveFlag.rotate]
  /// szandekosan kimarad (ADR 0036 F1-D4): elforgatott terkepen a vitorlazo
  /// elveszti az eszak-referenciat, es nincs kezenfekvo "vissza eszakra".
  static const int _interactiveFlags =
      InteractiveFlag.drag |
      InteractiveFlag.flingAnimation |
      InteractiveFlag.pinchMove |
      InteractiveFlag.pinchZoom |
      InteractiveFlag.doubleTapZoom;

  static LatLng _toLatLng(Coordinate c) => LatLng(c.latitude, c.longitude);

  @override
  State<TrackMap> createState() => _TrackMapState();
}

class _TrackMapState extends State<TrackMap> {
  /// A kamera ujrailleszteshez kell (A2-D2). Azert State-mezo, mert a
  /// build-ben letrehozott controller minden ujraepiteskor kicserelodne, es az
  /// illesztes kiszamithatatlanul elmaradna (A2-D5).
  final MapController _mapController = MapController();

  /// Meg csak az elso viewport-meretvaltozas van hatra (a nulla -> valodi
  /// meret atmenet), vagy az mar lezajlott?
  ///
  /// A kezdeti illesztest a `MapOptions.initialCameraFit` vegzi, ezert az
  /// elso esemenyre nem szabad ujrailleszteni: a `flutter_map` a
  /// kameravaltasra ujratervezi a csempe-keszletet, es a mar futo kereseket
  /// eldobja. A kartyan a kamera tobbe nem mozdul, tehat az igy kimarado
  /// csempek VEGLEG szurkek maradnak (on-device igazolt regresszio).
  bool _isFirstSizeChange = true;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final height = widget.height;
    // A lekerekites a kartya sajatja; a nagy nezet elig kifut a szelekig.
    final isCard = height != null;
    if (widget.points.isEmpty) {
      return Container(
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: isCard ? BorderRadius.circular(TrackMap._radius) : null,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            widget.emptyLabel,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    final trackLatLng = [
      for (final p in widget.points) TrackMap._toLatLng(p.position),
    ];
    final map = FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCameraFit: _cameraFit(),
        initialCenter: trackLatLng.first,
        initialZoom: 14,
        interactionOptions: InteractionOptions(
          flags: widget.isInteractive
              ? TrackMap._interactiveFlags
              : InteractiveFlag.none,
        ),
        onMapEvent: _onMapEvent,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.csakos.foretack',
          // A flutter_map harom argumentuma itt elnyelodik: a hivot csak az
          // erdekli, hogy VOLT hiba (ADR 0036 F2-D13).
          errorTileCallback: (_, _, _) => widget.onTileLoadError?.call(),
        ),
        PolylineLayer(polylines: _buildSpeedPolylines(trackLatLng)),
        MarkerLayer(
          markers: [
            for (final m in widget.marks)
              Marker(
                point: TrackMap._toLatLng(m.position),
                width: widget.showMarkLabels
                    ? MarkPin.labelledWidth
                    : MarkPin.size,
                height: widget.showMarkLabels
                    ? MarkPin.labelledHeight
                    : MarkPin.size,
                child: MarkPin(
                  label: '${m.sequence}',
                  name: widget.showMarkLabels ? m.name : null,
                ),
              ),
          ],
        ),
        // A kartyan a terkep IgnorePointer alatt ul (F1-D2), ott a
        // RichAttributionWidget osszecsukott badge-e halott ikon lenne: nem
        // lehet kinyitni. A nagy nezetrol pedig az F2 exportal, es abbol a
        // badge-bol egy capture-on csak az ikon latszana -- ODbL-hez az sem
        // eleg (ADR 0036 F2-D10 + A1-D6). Ezert mindket modban ugyanaz a
        // mindig lathato szoveges kredit all.
        const MapAttribution(),
      ],
    );
    if (!isCard) return map;
    return ClipRRect(
      borderRadius: BorderRadius.circular(TrackMap._radius),
      child: SizedBox(height: height, child: map),
    );
  }

  /// A track ES a bojak egyuttes befoglalo-dobozara illeszto kamera, vagy
  /// `null`, ha kettonel kevesebb pont van (a zero-meretu fit elkerulese
  /// vegett -> ilyenkor az initialCenter/initialZoom lep eletbe).
  ///
  /// Ket helyrol kell: a kezdeti illesztesnel es minden meretvaltozaskor
  /// (A2-D2), ezert nem inline szamoljuk a build-ben.
  CameraFit? _cameraFit() {
    final fitPoints = [
      for (final p in widget.points) TrackMap._toLatLng(p.position),
      for (final m in widget.marks) TrackMap._toLatLng(m.position),
    ];
    if (fitPoints.length < 2) return null;
    return CameraFit.bounds(
      bounds: LatLngBounds.fromPoints(fitPoints),
      padding: const EdgeInsets.all(24),
    );
  }

  /// A viewport meretvaltozasakor (eszkoz-forgatas, split-screen) ujrailleszti
  /// a kamerat a teljes trackre. A kezi nagyitas ilyenkor elveszik -- ez
  /// szandekos (A2-D3): kiszamithato es allapotmentes.
  void _onMapEvent(MapEvent event) {
    if (event is! MapEventNonRotatedSizeChange) return;
    // Az elso esemeny a kezdeti elrendezes, nem valodi meretvaltozas: azt a
    // MapOptions.initialCameraFit mar leilleszette. Csak jelezzuk, hogy
    // megtortent, es kilepunk -- lasd az _isFirstSizeChange doc-kommentjet.
    if (_isFirstSizeChange) {
      _isFirstSizeChange = false;
      return;
    }
    final fit = _cameraFit();
    if (fit == null) return;
    // Az esemeny a postFrameCallbacks fazisban erkezik, NEM build/layout
    // kozben (merve) -- a fitCamera setState-je itt legalis, szinkron hivhato.
    // Halasztani viszont tilos: az addPostFrameCallback maga nem utemez
    // keretet, es forgataskor a terkep sem utemez (nincs mit mozdulnia), igy a
    // halasztott callback sosem futna le.
    _mapController.fitCamera(fit);
  }

  /// A track-et szakaszonkenti [Polyline]-okra bontja: minden szakasz a kezdo-
  /// pontja sebesseg-savjanak szinevel, a szomszedos azonos-szinu szakaszokat
  /// egyetlen [Polyline]-ba vonva (run-merge, A4-D4). Igy a [Polyline]-ok
  /// szama a sav-valtasoke, nem a pontoke.
  List<Polyline> _buildSpeedPolylines(List<LatLng> latLng) {
    final segmentCount = latLng.length - 1;
    if (segmentCount < 1) return const <Polyline>[];
    final segmentColors = [
      for (var i = 0; i < segmentCount; i++)
        colorForTrackSpeed(widget.points[i].sogMps),
    ];
    final polylines = <Polyline>[];
    var runStart = 0;
    for (var j = 1; j <= segmentCount; j++) {
      // A run lezar, ha a szin valt vagy elertuk a track veget. A [runStart,
      // j) szakaszok a [runStart..j] pontokat fedik -> sublist(runStart, j+1).
      if (j == segmentCount || segmentColors[j] != segmentColors[runStart]) {
        polylines.add(
          Polyline(
            points: latLng.sublist(runStart, j + 1),
            color: segmentColors[runStart],
            strokeWidth: 4,
          ),
        );
        runStart = j;
      }
    }
    return polylines;
  }
}
