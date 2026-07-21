import 'package:flutter/material.dart';
import 'package:watch/theme/watch_colors.dart';

/// Teljes-képernyős sekély-víz riasztás az órán (ADR 0031 D4,
/// ARCHITECTURE.md 11.3).
///
/// A `DepthWarning` az órán szándékos kivétel a critical-warning ikonos
/// megjelenítés alól: zátonyveszélynél a kormányos a szeme sarkából is
/// észre kell vegye, ezért az egész lapot elfoglalja.
///
/// **Ambient-változat:** ambientben nincs nagy piros mező (OLED burn-in +
/// energia) és nincs bezárás gomb sem — az érintés ambientben nem
/// megbízható. Ilyenkor fekete háttéren piros szöveg marad.
///
/// A widget natív-mentes és állapotmentes: a láthatóságot és a bezárt
/// állapotot a `RaceShell` tartja (`depth_alert_edge.dart`).
class DepthAlertOverlay extends StatelessWidget {
  /// Létrehozza az overlayt a pillanatnyi [depthMeters] mélységgel.
  const DepthAlertOverlay({
    required this.depthMeters,
    required this.colors,
    required this.ambient,
    required this.onDismiss,
    super.key,
  });

  /// A riasztás pillanatnyi mélysége méterben (a payloadból, élőben frissül).
  final double depthMeters;

  /// A téma szín-tokenjei.
  final WatchColors colors;

  /// Ambient mód: tompított, gomb nélküli változat.
  final bool ambient;

  /// A bezárás gomb visszahívása. Ambientben nincs gomb, így nem hívódik.
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final background = ambient ? colors.background : colors.critical;
    final foreground = ambient ? colors.critical : colors.text;

    return GestureDetector(
      // Az üres onTap kell ahhoz, hogy a GestureDetector egyáltalán
      // hit-testelődjön: enélkül az overlay alatti PageView megkapná a
      // húzásokat, és a riasztás alatt észrevétlenül elmozdulna a nézet.
      onTap: () {},
      behavior: HitTestBehavior.opaque,
      child: ColoredBox(
        color: background,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'SEKÉLY VÍZ',
                style: TextStyle(
                  color: foreground,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${depthMeters.toStringAsFixed(1)} m',
                style: TextStyle(
                  color: foreground,
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (!ambient) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onDismiss,
                  child: Text(
                    'Bezár',
                    style: TextStyle(color: foreground, fontSize: 15),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
