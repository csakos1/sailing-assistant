import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:phone/features/race_detail/export/track_export_content.dart';
import 'package:phone/features/race_detail/export/track_export_layout.dart';

/// Az export-kép nagyítása (ADR 0036 A1-D4): fixen 3×.
///
/// Szándékosan NEM a `MediaQuery.devicePixelRatio`: a megosztott kép mérete
/// legyen eszköztől független és reprodukálható. Feljebb a GPU maximális
/// textúra-mérete korlátoz, és a raszter csempék élességén sem javítana.
const double exportPixelRatio = 3;

// A keret színei szándékosan itt élnek, nem a `marine_colors.dart`-ban: a
// megosztott kép téma- és eszközfüggetlen artefaktum, míg a marine paletta
// az élő UI-é. Ha a kettő valaha összeér, a kiemelés egy sor.
const Color _frameColor = Color(0xFF10202B);
const Color _frameTextColor = Color(0xFFF2F5F7);
const Color _frameMutedTextColor = Color(0xFF93A7B4);

/// Kirendereli a megosztható track-képet a látható nézet capture-jéből.
///
/// A `boundary` a fullscreen nézet `RepaintBoundary`-jének render-objektuma
/// — az F2-D9 szerint a képre az a kivágás és nagyítás kerül, amit a
/// felhasználó a képernyőn lát.
///
/// A capture 1:1 arányban kerül a helyére: a vászon a capture LOGIKAI
/// méretén dolgozik, és a `pixelRatio`-t egyetlen `scale` hívás viszi rá az
/// egészre, ezért a 3×-os capture pontosan a saját pixeleire esik.
///
/// A visszaadott kép `dispose()`-olása a hívó felelőssége.
Future<ui.Image> renderTrackExportImage({
  required RenderRepaintBoundary boundary,
  required TrackExportContent content,
}) async {
  final layout = TrackExportLayout.forCaptureSize(boundary.size);
  final capture = await boundary.toImage(pixelRatio: exportPixelRatio);
  try {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(exportPixelRatio);
    _paintExportImage(canvas, layout, content, capture);
    final picture = recorder.endRecording();
    try {
      return await picture.toImage(
        (layout.imageSize.width * exportPixelRatio).round(),
        (layout.imageSize.height * exportPixelRatio).round(),
      );
    } finally {
      picture.dispose();
    }
  } finally {
    capture.dispose();
  }
}

/// A három sáv megfestése: keret, capture, majd a keret szövegei.
void _paintExportImage(
  Canvas canvas,
  TrackExportLayout layout,
  TrackExportContent content,
  ui.Image capture,
) {
  assert(
    content.statTexts.length == layout.statCells.length,
    'The export content must supply a text for every stat cell.',
  );

  final source = Rect.fromLTWH(
    0,
    0,
    capture.width.toDouble(),
    capture.height.toDouble(),
  );
  final frame = Paint()..color = _frameColor;
  canvas
    ..drawRect(layout.headerBand, frame)
    ..drawRect(layout.statsBand, frame)
    ..drawImageRect(capture, source, layout.captureRect, Paint());

  _paintSingleLine(
    canvas,
    text: content.raceName,
    box: layout.titleRect,
    fontSize: TrackExportLayout.titleFontSize,
    color: _frameTextColor,
    weight: FontWeight.w600,
    align: TextAlign.left,
  );
  _paintSingleLine(
    canvas,
    text: content.dateLabel,
    box: layout.dateRect,
    fontSize: TrackExportLayout.dateFontSize,
    color: _frameMutedTextColor,
    weight: FontWeight.w400,
    align: TextAlign.left,
  );

  for (var index = 0; index < layout.statCells.length; index++) {
    final cell = layout.statCells[index];
    final text = content.statTexts[index];
    _paintSingleLine(
      canvas,
      text: text.label,
      box: cell.labelRect,
      fontSize: TrackExportLayout.statLabelFontSize,
      color: _frameMutedTextColor,
      weight: FontWeight.w400,
      align: TextAlign.center,
    );
    _paintSingleLine(
      canvas,
      text: text.value,
      box: cell.valueRect,
      fontSize: TrackExportLayout.statValueFontSize,
      color: _frameTextColor,
      weight: FontWeight.w600,
      align: TextAlign.center,
    );
  }
}

/// Egy sornyi szöveg a megadott dobozba, függőlegesen középre igazítva.
///
/// A `TextPainter` a doboz szélességére kap szoros kényszert (`minWidth` ==
/// `maxWidth`), különben a középre igazításnak nem lenne mihez igazodnia.
/// A szöveg egy sorban marad és ellipszissel csonkolódik: a sávok magassága
/// fix, tehát a hosszú versenynév nem tördelheti szét az elrendezést.
void _paintSingleLine(
  Canvas canvas, {
  required String text,
  required Rect box,
  required double fontSize,
  required Color color,
  required FontWeight weight,
  required TextAlign align,
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(color: color, fontSize: fontSize, fontWeight: weight),
    ),
    textAlign: align,
    textDirection: TextDirection.ltr,
    maxLines: 1,
    ellipsis: '…',
  )..layout(minWidth: box.width, maxWidth: box.width);

  final top = box.top + (box.height - painter.height) / 2;
  painter
    ..paint(canvas, Offset(box.left, top))
    ..dispose();
}
