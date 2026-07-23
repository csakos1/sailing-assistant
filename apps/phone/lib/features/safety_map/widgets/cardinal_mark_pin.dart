import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:phone/app/marine_colors.dart';

/// Egy kardinális bója IALA-jele: topjel két kúpból, alatta a sávozott
/// test (ADR 0037 D15).
///
/// **Felirat nélkül.** A kardinálisok jele önmagában olvasható — a
/// topjel iránya és a sávozás mondja meg, merre van a biztonságos víz —,
/// a katalógus címkéi pedig diagnosztikai azonosítók, nem UI-szövegek.
/// A tihanyi csőben a hét jelölő sűrűn áll, a feliratok összeérnének.
///
/// **A test közepe esik a koordinátára.** A `Marker` a dobozt középre
/// igazítja, ezért a doboz FÜGGŐLEGESEN SZIMMETRIKUS: a test fölött a
/// topjel, alatta ugyanakkora üres sáv áll. Enélkül a bója a valós
/// pozíciójától délre látszana — z15-ön ez több tíz méter, egy száz méter
/// széles csatornában érdemi hiba. Ez a `MarkPin` bevált mintája.
class CardinalMarkPin extends StatelessWidget {
  /// Kardinális bójajel a megadott fajtával.
  const CardinalMarkPin({required this.direction, super.key});

  /// A `Marker`-doboz szélessége.
  static const double width = 18;

  /// A `Marker`-doboz magassága: a test, fölötte a topjel a réssel,
  /// alatta ugyanakkora üres sáv.
  static const double height = _bodyHeight + 2 * (_topmarkHeight + _gap);

  /// A kardinális fajtája — ez határozza meg a topjelet és a sávozást.
  final CardinalDirection direction;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(width, height),
      painter: _CardinalMarkPainter(direction),
    );
  }
}

const double _bodyWidth = 9;
const double _bodyHeight = 20;
const double _topmarkWidth = 13;
const double _topmarkHeight = 14;
const double _gap = 2;

/// A kardinális jel rajzolója.
///
/// `CustomPaint`, mert a topjel háromszögei Flutterben vagy `Canvas`-t,
/// vagy egyedi `ClipPath`-t kívánnak — az utóbbi ugyanaz a komplexitás a
/// `Canvas` előnyei nélkül. A négy irány és a sávozás egyetlen festőben
/// elfér, kimerítő `switch`-csel: egy ötödik kardinális-fajta fordítási
/// hibaként jelentkezne.
class _CardinalMarkPainter extends CustomPainter {
  const _CardinalMarkPainter(this.direction);

  final CardinalDirection direction;

  @override
  void paint(Canvas canvas, Size size) {
    final centreX = size.width / 2;
    final bodyTop = size.height / 2 - _bodyHeight / 2;
    _paintTopmark(canvas, centreX, bodyTop - _gap - _topmarkHeight);
    _paintBody(canvas, centreX, bodyTop);
  }

  /// A test sávozása. Az IALA-séma: észak fekete/sárga, dél sárga/fekete,
  /// kelet fekete–sárga–fekete, nyugat sárga–fekete–sárga.
  void _paintBody(Canvas canvas, double centreX, double top) {
    final bands = switch (direction) {
      CardinalDirection.north => const [cardinalBlack, cardinalYellow],
      CardinalDirection.east => const [
        cardinalBlack,
        cardinalYellow,
        cardinalBlack,
      ],
      CardinalDirection.south => const [cardinalYellow, cardinalBlack],
      CardinalDirection.west => const [
        cardinalYellow,
        cardinalBlack,
        cardinalYellow,
      ],
    };
    final left = centreX - _bodyWidth / 2;
    final bandHeight = _bodyHeight / bands.length;
    final fill = Paint();
    for (var index = 0; index < bands.length; index++) {
      fill.color = bands[index];
      canvas.drawRect(
        Rect.fromLTWH(left, top + index * bandHeight, _bodyWidth, bandHeight),
        fill,
      );
    }
    // Fehér keret: a csempe-háttér tetszőleges színű lehet, e nélkül a
    // fekete sáv sötét vízfelületen eltűnne.
    canvas.drawRect(
      Rect.fromLTWH(left, top, _bodyWidth, _bodyHeight),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  /// A topjel két kúpja. Észak: mindkettő fölfelé; dél: mindkettő lefelé;
  /// kelet: talpával összefordítva (rombusz); nyugat: csúcsával
  /// összefordítva (homokóra).
  void _paintTopmark(Canvas canvas, double centreX, double top) {
    final (upperPointsUp, lowerPointsUp) = switch (direction) {
      CardinalDirection.north => (true, true),
      CardinalDirection.east => (true, false),
      CardinalDirection.south => (false, false),
      CardinalDirection.west => (false, true),
    };
    const coneHeight = _topmarkHeight / 2;
    final path = Path()
      ..addPath(
        _cone(centreX, top, coneHeight, pointsUp: upperPointsUp),
        Offset.zero,
      )
      ..addPath(
        _cone(centreX, top + coneHeight, coneHeight, pointsUp: lowerPointsUp),
        Offset.zero,
      );
    canvas
      ..drawPath(path, Paint()..color = cardinalBlack)
      ..drawPath(
        path,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
  }

  Path _cone(
    double centreX,
    double top,
    double height, {
    required bool pointsUp,
  }) {
    const half = _topmarkWidth / 2;
    final path = Path();
    if (pointsUp) {
      path
        ..moveTo(centreX, top)
        ..lineTo(centreX + half, top + height)
        ..lineTo(centreX - half, top + height);
    } else {
      path
        ..moveTo(centreX - half, top)
        ..lineTo(centreX + half, top)
        ..lineTo(centreX, top + height);
    }
    return path..close();
  }

  @override
  bool shouldRepaint(_CardinalMarkPainter oldDelegate) =>
      oldDelegate.direction != direction;
}
