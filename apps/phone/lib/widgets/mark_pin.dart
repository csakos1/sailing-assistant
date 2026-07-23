import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:phone/app/marine_colors.dart';

/// Egy boja-jelolo: szamozott korong feher kerettel (port-piros), opcionalis
/// nev-felirattal a korong alatt (ADR 0036 F1-D6).
///
/// Felirattal a doboz FUGGOLEGESEN SZIMMETRIKUS: a korong felett es alatt
/// ugyanakkora sav all, igy a doboz kozepe tovabbra is a korong kozepe -- a
/// [Marker] alapertelmezett kozepre-igazitasa mellett a korong pontosan a
/// boja koordinatajara esik. Ezert nem egyszeruen "korong + alatta szoveg".
class MarkPin extends StatelessWidget {
  /// Szamozott bojajel, opcionalis nev-felirattal a korong alatt.
  const MarkPin({
    required this.label,
    this.name,
    this.isActive = false,
    super.key,
  });

  /// A korong elerheto merete felirat nelkul (a [Marker] dobozanak merete).
  static const double size = 22;

  /// A nev-savok magassaga a korong felett es alatt.
  static const double _nameSlot = 20;

  /// A feliratos [Marker]-doboz merete.
  static const double labelledWidth = 96;

  /// A feliratos doboz magassaga: a korong, felette es alatta egy-egy
  /// nev-sav.
  static const double labelledHeight = size + 2 * _nameSlot;

  /// A korong alap keretvastagsaga.
  static const double _borderWidth = 1.5;

  /// A kiemelt boja vastagabb kerete. A doboz MERETE NEM valtozik: a
  /// fuggoleges szimmetria a meretbol jon, tehat egy nagyobb aktiv jel a
  /// valos koordinatajatol elcsuszva rajzolodna (ADR 0037 D14, D15).
  static const double _activeBorderWidth = 3.5;

  /// A boja sorszama a korongon.
  final String label;

  /// A boja neve a korong alatt; `null` eseten csak a korong latszik.
  final String? name;

  /// Kiemelt-e a boja: az elo terkepen a soron kovetkezo, megkerulendo
  /// boja (ADR 0037 D14). A post-race track-terkep nem hasznalja, ott
  /// minden boja mar megkerult.
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final disc = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: portColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: isActive ? _activeBorderWidth : _borderWidth,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    final markName = name;
    if (markName == null) return disc;
    return Column(
      children: [
        // Felso ures sav: ez tartja a korongot a doboz kozepen.
        const SizedBox(height: _nameSlot),
        disc,
        SizedBox(
          height: _nameSlot,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                // A tile-hatter tetszoleges szinu lehet -> sotet pirula.
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                markName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
