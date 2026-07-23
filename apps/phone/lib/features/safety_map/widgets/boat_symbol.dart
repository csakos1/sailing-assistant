import 'dart:math' as math;

import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:phone/app/marine_colors.dart';

/// A saját hajó jele az élő biztonsági térképen (ADR 0037 D11).
///
/// **A tájolás a COG, nem a HDG.** A felhasználó kérdése („ha ebbe az
/// irányba haladok, hol jövök ki a bójákhoz képest") track-szemantika: a
/// sodródás és az áram miatt a hajó nem az orra irányába megy, és a
/// tihanyi csőben van valós áramlás. Ráadásul a ZG100 heading-függő
/// mágneses hibája miatt az orr-irány önmagában sem megbízható (ADR 0020).
///
/// **Irány nélkül korong, nem fagyott nyíl.** Ha a [course] `null` — nincs
/// COG, vagy a sebesség a küszöb alatt van —, a jel irány nélküli korong.
/// Egy utolsó ismert irányba fagyott nyíl ugyanolyan magabiztosan nézne
/// ki, mint az élő; a korong kimondja, hogy az irány ismeretlen. Ez a
/// D12 „a hiányzó vonal őszinte" elvének és a pozíció nélküli üres
/// állapotnak ugyanaz a szabálya.
class BoatSymbol extends StatelessWidget {
  /// Hajó-jel a megadott haladási iránnyal, vagy irány nélkül.
  const BoatSymbol({required this.course, super.key});

  /// A jel éle képpontban — ez a `Marker`-doboz mérete is.
  static const double size = 26;

  /// A megjelenítendő haladási irány (COG), vagy `null`, ha nincs
  /// megbízható irány.
  final Bearing? course;

  @override
  Widget build(BuildContext context) {
    final heading = course;
    if (heading == null) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: boatColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
      );
    }
    // A Transform.rotate pozitív szöggel az óramutató járásával egyezően
    // forgat, a bearing pedig északtól ugyanígy nő — a nyíl alaphelyzetben
    // fölfelé (északra) néz, tehát nincs korrekció.
    return Transform.rotate(
      angle: heading.degrees * math.pi / 180,
      child: const CustomPaint(painter: _BoatArrowPainter()),
    );
  }
}

/// A hajó-nyíl rajzolója: hátul bevágott háromszög, fehér kerettel.
///
/// A bevágás adja az irány-érzetet — egy sima háromszög fejjel lefelé is
/// háromszögnek látszik, a bevágott alap viszont egyértelműen a hátulja.
class _BoatArrowPainter extends CustomPainter {
  const _BoatArrowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width * 0.86, size.height)
      ..lineTo(size.width / 2, size.height * 0.72)
      ..lineTo(size.width * 0.14, size.height)
      ..close();
    canvas
      ..drawPath(path, Paint()..color = boatColor)
      ..drawPath(
        path,
        // Fehér keret: a csempe-háttér tetszőleges színű lehet.
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeJoin = StrokeJoin.round,
      );
  }

  @override
  bool shouldRepaint(_BoatArrowPainter oldDelegate) => false;
}
