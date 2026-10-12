import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/features/race_setup/widgets/form_card.dart';

/// A kártya legkisebb magassága (33a).
const double _minHeight = 62;

/// A jobb oldali érintési cella (33a).
const double _cellSize = 44;

/// A „Rajt időpontja" kártya (33a, 33b).
///
/// Állapot nélküli: a formázott értéket, a figyelmeztetést és a két
/// akciót a hívó adja. Érintésre a választó nyílik ([onOpen]); kitöltve
/// a jobb cella „×", ami kiüríti a mezőt ([onClear]), üresen „›".
class StartTimeCard extends StatelessWidget {
  /// Egy kártya. A [value] `null`, ha nincs tervezett rajt.
  const StartTimeCard({
    required this.label,
    required this.emptyLabel,
    required this.clearTooltip,
    required this.onOpen,
    required this.onClear,
    this.value,
    this.note,
    super.key,
  });

  /// A verzál címke („RAJT IDŐPONTJA").
  final String label;

  /// A kitöltött érték („2026. okt. 10. · 09:00"), vagy `null`.
  final String? value;

  /// Az üres állapot szövege.
  final String emptyLabel;

  /// Egy halk figyelmeztetés az érték alatt (pl. elmúlt időpont), vagy
  /// `null`.
  final String? note;

  /// A törlés-gomb tooltipje.
  final String clearTooltip;

  /// A választó megnyitása.
  final VoidCallback onOpen;

  /// A mező kiürítése.
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // A foretackTheme regisztrálja a TextTones-t → a fában mindig jelen van.
    final tones = Theme.of(context).extension<TextTones>()!;
    final value = this.value;
    final note = this.note;
    final isEmpty = value == null;

    return FormCard(
      child: InkWell(
        onTap: onOpen,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: _minHeight),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 9, 4, 9),
            child: Row(
              spacing: 12,
              children: [
                Icon(
                  Icons.event_outlined,
                  size: 18,
                  color: isEmpty ? tones.low : scheme.onSurfaceVariant,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 5,
                    children: [
                      Text(
                        label,
                        style: railLabelStyle.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      if (value == null)
                        Text(
                          emptyLabel,
                          style: supportTextStyle.copyWith(
                            fontSize: 14,
                            color: tones.low,
                          ),
                        )
                      else
                        Text(
                          value,
                          style: numeralMicroStyle.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: scheme.onSurface,
                          ),
                        ),
                      if (note != null)
                        Text(
                          note,
                          style: supportTextStyle.copyWith(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w400,
                            height: 1.4,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox.square(
                  dimension: _cellSize,
                  child: isEmpty
                      ? Icon(Icons.chevron_right, color: tones.low)
                      : IconButton(
                          onPressed: onClear,
                          icon: const Icon(Icons.close, size: 20),
                          tooltip: clearTooltip,
                          color: scheme.onSurfaceVariant,
                          padding: EdgeInsets.zero,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
