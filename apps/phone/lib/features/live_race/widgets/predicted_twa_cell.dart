import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:phone/app/foretack_typography.dart';
import 'package:phone/app/text_tones.dart';
import 'package:phone/features/live_race/widgets/confidence_dots.dart';
import 'package:phone/features/live_race/widgets/main_column_cell.dart';
import 'package:phone/features/live_race/widgets/twa_value.dart';
import 'package:phone/l10n/app_localizations.dart';

/// A fő oszlop hero-cellája: a következő bójánál várható TWA (§8.7,
/// ADR 0020 D7, ADR 0023 D9, ADR 0042 D8, D12).
///
/// A `next_twa_value.dart` utódja: a v1-ben a cella tartalmát építette, itt
/// viszont a **teljes cellát**, mert az 1c elrendezésben a három jelzés
/// három különböző rekeszbe került:
///
/// - a [confidence] pöttyei a felirat sorába (`trailing`),
/// - a [bandDegrees] hibasáv és a „TARTOTT" pill az érték alá (`support`),
/// - a [twdQuality] pedig továbbra is a hero **opacitásán** jelenik meg.
///
/// A három csatorna ortogonális, ezért nem ütköznek: a szín a konfidenciáé,
/// az opacitás a TWD-frissességé, a szám maga high-contrast semleges.
class PredictedTwaCell extends StatelessWidget {
  /// A hero-cella.
  const PredictedTwaCell({
    required this.twa,
    required this.twdQuality,
    required this.confidence,
    this.bandDegrees,
    super.key,
  });

  /// A következő bójánál várható, előjeles TWA, vagy `null` (`—`).
  final Angle? twa;

  /// A predikciót tápláló TWD-derivált frissessége (ADR 0020 D7).
  final TwdQuality twdQuality;

  /// A wind-shift trend megbízhatósága, vagy `null`, ha nincs predikció.
  final WindShiftConfidence? confidence;

  /// A predikció előrejelzési hibasávja fokban (`±`), vagy `null`
  /// (ADR 0023 D9). A [confidence] folytonos megfelelője.
  final double? bandDegrees;

  @override
  Widget build(BuildContext context) {
    // Az AppLocalizations.of `!`-ja biztonságos a MaterialApp alatt, a
    // TextTones-t pedig a foretackTheme regisztrálja.
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final tones = theme.extension<TextTones>()!;
    // Lokálisra másoljuk a null-promócióhoz a collection-if alatt.
    final confidence = this.confidence;
    final band = bandDegrees;
    final isHeld = twdQuality == TwdQuality.held;

    return MainColumnCell(
      label: l10n.liveTwaNext,
      padding: const EdgeInsets.fromLTRB(20, 16, 14, 14),
      trailing: confidence == null ? null : ConfidenceDots(confidence),
      support: (band == null && !isHeld)
          ? null
          : Row(
              children: [
                if (band != null)
                  Text(
                    '±${band.round()}°',
                    style: numeralMicroStyle.copyWith(color: tones.low),
                  ),
                if (band != null && isHeld) const SizedBox(width: 10),
                if (isHeld) _HeldPill(label: l10n.liveTwdHeld),
              ],
            ),
      // Csak a hero tompul; a hibasáv és a pöttyök teljes opacitáson
      // maradnak, hogy a held-állapot olvasható legyen.
      child: Opacity(
        opacity: isHeld ? 0.6 : 1.0,
        child: TwaValue(twa, style: numeralHeroStyle),
      ),
    );
  }
}

/// A „tartott TWD" pill a hero alatt (ADR 0042 D12).
///
/// Kontúros, nem tömör: a tartott érték **nem** hibaállapot — a legutóbbi jó
/// szélirányt visszük tovább —, ezért a jelzés semleges tokeneket használ, és
/// a hero tompításával együtt olvasandó.
class _HeldPill extends StatelessWidget {
  const _HeldPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outline),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: sectionLabelStyle.copyWith(color: scheme.onSurfaceVariant),
      ),
    );
  }
}
