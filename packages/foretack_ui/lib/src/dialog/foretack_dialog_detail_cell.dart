import 'package:flutter/material.dart';
import 'package:foretack_ui/src/dialog/foretack_dialog_action.dart';
import 'package:foretack_ui/src/theme/foretack_typography.dart';

/// A dialógus adatcellája: mi érintett (ADR 0048 Addendum 4 K13, K22,
/// makett 11a, 13j).
///
/// Keretes doboz `surface` háttérrel; soronként címke balra, mono érték
/// jobbra, a sorok között hairline.
class ForetackDialogDetailCell extends StatelessWidget {
  /// Adatcella a [details] soraival.
  const ForetackDialogDetailCell({required this.details, super.key});

  /// A sorok, fentről lefelé.
  final List<ForetackDialogDetail> details;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border.all(color: scheme.outline),
      ),
      child: Column(
        children: [
          for (var index = 0; index < details.length; index++)
            DecoratedBox(
              decoration: BoxDecoration(
                border: index == details.length - 1
                    ? null
                    : Border(
                        bottom: BorderSide(color: scheme.outlineVariant),
                      ),
              ),
              child: SizedBox(
                height: 38,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Text(
                        details[index].label,
                        style: supportTextStyle.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          details[index].value,
                          textAlign: TextAlign.end,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: statusLabelStyle.copyWith(
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
