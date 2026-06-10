import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:phone/features/live_race/widgets/confidence_dots.dart';
import 'package:phone/features/live_race/widgets/twa_value.dart';
import 'package:phone/l10n/app_localizations.dart';

/// A „TWA köv." cella tartalma: a predikált TWA hero + két, egymástól
/// független megbízhatósági csatorna (§8.7, ADR 0020 D7).
///
/// A [twdQuality] a hero OPACITÁSÁN jelenik meg: `held` → tompított (0.6) +
/// diszkrét „tartott" felirat; `live`/`unavailable` → teljes. (Az
/// `unavailable` „—"-jét a null [twa] adja, külön nem tompítunk.) A
/// [confidence] a hero ALATT három pötty; `null` → nincs aktív predikció.
/// A két jel külön vizuális csatornán (opacitás vs. pötty), így nem ütközik.
class NextTwaValue extends StatelessWidget {
  /// A „TWA köv." cella.
  const NextTwaValue({
    required this.twa,
    required this.twdQuality,
    required this.confidence,
    super.key,
  });

  /// A következő bójánál várható, előjeles TWA, vagy `null` (`—`).
  final Angle? twa;

  /// A predikciót tápláló TWD-derivált frissessége (ADR 0020 D7).
  final TwdQuality twdQuality;

  /// A wind-shift trend megbízhatósága, vagy `null`, ha nincs predikció.
  final WindShiftConfidence? confidence;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isHeld = twdQuality == TwdQuality.held;
    // Lokálisra másoljuk a null-promócióhoz a collection-if alatt.
    final confidence = this.confidence;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Csak a hero tompul; a „tartott" felirat és a pöttyök teljes
        // opacitáson maradnak, hogy a held-állapot olvasható legyen.
        Opacity(opacity: isHeld ? 0.6 : 1.0, child: TwaValue(twa)),
        if (isHeld) ...[
          const SizedBox(height: 2),
          Text(
            l10n.liveTwdHeld,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (confidence != null) ...[
          const SizedBox(height: 4),
          ConfidenceDots(confidence),
        ],
      ],
    );
  }
}
