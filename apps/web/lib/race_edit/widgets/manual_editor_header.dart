import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:foretack_web/app/web_layout.dart';
import 'package:foretack_web/l10n/web_localizations.dart';

/// A kézi szerkesztő státusz-sávja (ADR 0048 Addendum 1 G6, makett 14r):
/// üres keretes négyzet és „KÉZI VERSENY", jobbra hogy telemetria nincs.
class ManualEditorHeader extends StatelessWidget {
  /// A kézi szerkesztő sávja.
  const ManualEditorHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = WebLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final tones = Theme.of(context).extension<TextTones>()!;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SizedBox(
        height: 48,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: WebLayout.columnInset,
          ),
          child: Row(
            children: [
              // A G6 „KÉZI" jele: üres keret, a telemetriás tele négyzete
              // helyett.
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: tones.low, width: 1.5),
                ),
                child: const SizedBox.square(dimension: 7),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.editManualCaps,
                style: statusLabelStyle.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Flexible(
                flex: 4,
                child: Text(
                  l10n.editManualNoTelemetryCaps,
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                  style: statusLabelStyle.copyWith(
                    fontSize: 9,
                    color: tones.low,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
