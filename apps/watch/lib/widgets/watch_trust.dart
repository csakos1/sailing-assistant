import 'package:flutter/material.dart';
import 'package:watch/theme/watch_colors.dart';

/// Igaz, ha a payload `twdQuality` mezője `held` — ekkor a köv-TWA hero
/// tompul és „tartott" jelet kap (ADR 0020 D7). A String a payload-kontraktus
/// (`TwdQuality.name`); ismeretlen/`null` → nem held (biztonságos default).
bool isTwdHeld(String? twdQuality) => twdQuality == 'held';

/// A `shiftConfidence` payload-String → kitöltött pöttyök száma (1..3), vagy
/// `null`, ha nincs aktív predikció / ismeretlen érték. A String a
/// payload-kontraktus (`WindShiftConfidence.name`); a leképezés a phone
/// `confidence_dots`-ét követi (§10.4).
int? confidenceDotCount(String? shiftConfidence) => switch (shiftConfidence) {
  'low' => 1,
  'medium' => 2,
  'high' => 3,
  _ => null,
};

/// Három-szegmenses pötty-indikátor a predikció-konfidenciához (§10.4):
/// 1→`●○○`, 2→`●●○`, 3→`●●●`. A shape hordozza az infót (színvak-safe), a
/// watch-palettával színezve (a phone `ConfidenceColors` itt nem elérhető).
class WatchConfidenceDots extends StatelessWidget {
  /// Létrehozza a pötty-sort a kitöltött szegmensek [filled] számával (1..3).
  const WatchConfidenceDots({
    required this.filled,
    required this.colors,
    super.key,
  });

  /// A kitöltött pöttyök száma (1..3).
  final int filled;

  /// A téma szín-tokenjei.
  final WatchColors colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final isOn = i < filled;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Icon(
            isOn ? Icons.circle : Icons.circle_outlined,
            size: 7,
            color: isOn ? colors.text : colors.textTertiary,
          ),
        );
      }),
    );
  }
}
