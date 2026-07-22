import 'package:flutter/painting.dart';

/// Egy statisztika-cella két szöveg-doboza: fölül a címke, alatta az érték.
typedef TrackExportStatCell = ({Rect labelRect, Rect valueRect});

// A sávok fix metrikái LOGIKAI pixelben. A pixelRatio szorzót (A1-D4) a
// renderer alkalmazza egyszer, a teljes vászonra — így ezek olvasható
// méretek maradnak, a geometria pedig tiszta aritmetika.
//
// A sor-magasságok szándékosan külön konstansok, nem a betűméret
// szorzatai: a tényleges sor-doboz a betűtípustól is függ, itt viszont
// determinisztikus, előre rögzített dobozokat akarunk.
const double _horizontalPadding = 20;

const double _headerPaddingTop = 18;
const double _headerPaddingBottom = 16;
const double _titleLineHeight = 28;
const double _titleToDateGap = 4;
const double _dateLineHeight = 17;

const double _statsPaddingTop = 14;
const double _statsPaddingBottom = 16;
const double _statLabelLineHeight = 14;
const double _statLabelToValueGap = 3;
const double _statValueLineHeight = 25;

/// Átlag sebesség, max sebesség, megtett út (F2-D11).
const int _statCellCount = 3;

/// A megosztható export-kép teljes geometriája, logikai pixelben.
///
/// Az elrendezés három vízszintes sávból áll (A1-D3):
///
/// ```text
/// fejléc-sáv      a verseny neve + a startdátum
/// capture-blokk   a RepaintBoundary képe, 1:1 arányban
/// statisztika     átlag / max / megtett út
/// ```
///
/// A kép szélessége **a capture szélessége**, ezért a térkép-blokk sem
/// átméretezést, sem levágást nem szenved. A két keret-sáv magassága fix,
/// tehát a szabad képarány (álló és fekvő egyaránt) érintetlenül hagyja
/// a keretet — csak a `captureRect` nő vagy zsugorodik.
///
/// Ez az osztály **nem raszterizál**: nincs `Canvas`, `Picture` vagy
/// `Image` a közelében, ezért aszinkron lépés és widget-fa nélkül
/// unit-tesztelhető. A festés — színek, betűtípus, igazítás — a renderer
/// dolga (F2b).
///
/// Igazítási szerződés a rendererrel: a `titleRect` és a `dateRect`
/// balra igazított szöveget vár, a cellák dobozai középre igazítottat.
class TrackExportLayout {
  const TrackExportLayout._({
    required this.imageSize,
    required this.headerBand,
    required this.captureRect,
    required this.statsBand,
    required this.titleRect,
    required this.dateRect,
    required this.statCells,
  });

  /// Kiszámolja a teljes kép geometriáját a capture logikai méretéből.
  ///
  /// A `captureSize` a `RepaintBoundary` render-objektumának mérete,
  /// tehát logikai pixel — nem a `toImage` kimeneti felbontása.
  factory TrackExportLayout.forCaptureSize(Size captureSize) {
    assert(
      captureSize.width > 0 && captureSize.height > 0,
      'The capture size must be positive.',
    );

    const titleTop = _headerPaddingTop;
    const dateTop = titleTop + _titleLineHeight + _titleToDateGap;
    const headerHeight = dateTop + _dateLineHeight + _headerPaddingBottom;

    const labelTop = _statsPaddingTop;
    const valueTop = labelTop + _statLabelLineHeight + _statLabelToValueGap;
    const statsHeight = valueTop + _statValueLineHeight + _statsPaddingBottom;

    final width = captureSize.width;
    final statsTop = headerHeight + captureSize.height;
    final textWidth = width - _horizontalPadding * 2;
    final cellWidth = textWidth / _statCellCount;

    return TrackExportLayout._(
      imageSize: Size(width, statsTop + statsHeight),
      headerBand: Rect.fromLTWH(0, 0, width, headerHeight),
      captureRect: Rect.fromLTWH(0, headerHeight, width, captureSize.height),
      statsBand: Rect.fromLTWH(0, statsTop, width, statsHeight),
      titleRect: Rect.fromLTWH(
        _horizontalPadding,
        titleTop,
        textWidth,
        _titleLineHeight,
      ),
      dateRect: Rect.fromLTWH(
        _horizontalPadding,
        dateTop,
        textWidth,
        _dateLineHeight,
      ),
      statCells: List<TrackExportStatCell>.generate(
        _statCellCount,
        (index) {
          final left = _horizontalPadding + cellWidth * index;
          return (
            labelRect: Rect.fromLTWH(
              left,
              statsTop + labelTop,
              cellWidth,
              _statLabelLineHeight,
            ),
            valueRect: Rect.fromLTWH(
              left,
              statsTop + valueTop,
              cellWidth,
              _statValueLineHeight,
            ),
          );
        },
        growable: false,
      ),
    );
  }

  /// A verseny nevének betűmérete a fejlécben.
  static const double titleFontSize = 22;

  /// A startdátum betűmérete a fejlécben.
  static const double dateFontSize = 13;

  /// A statisztika-cellák halvány címkéinek betűmérete.
  static const double statLabelFontSize = 11;

  /// A statisztika-cellák értékeinek betűmérete.
  static const double statValueFontSize = 20;

  /// A teljes kép mérete: a capture szélessége, a három sáv magassága.
  final Size imageSize;

  /// A felső keret-sáv, a verseny nevével és a startdátummal.
  final Rect headerBand;

  /// Ide kerül a capture képe, 1:1 arányban.
  final Rect captureRect;

  /// Az alsó keret-sáv, a három statisztika-cellával.
  final Rect statsBand;

  /// A verseny nevének szöveg-doboza a fejlécen belül.
  final Rect titleRect;

  /// A startdátum szöveg-doboza a fejlécen belül.
  final Rect dateRect;

  /// A három statisztika-cella, balról jobbra, egyenlő szélességgel.
  final List<TrackExportStatCell> statCells;
}
