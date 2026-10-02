import 'package:flutter/material.dart';
import 'package:foretack_ui/src/dialog/foretack_dialog_action.dart';
import 'package:foretack_ui/src/theme/foretack_typography.dart';

/// A Foretack közös dialógus-doboza (ADR 0047 E6, ADR 0048 Addendum 4
/// K13, makett 11a).
///
/// Szögletes doboz: cím, magyarázó szöveg, opcionális adatcella (mi
/// érintett), alul egyenlő szélességű akció-cellák hairline-nal. A kezdő
/// fókusz az első nem destruktív akción van. Az Esc a dialógus-útvonal
/// szokása szerint `null`-lal zár; a hívó ezt a biztonságos válasznak
/// veszi.
///
/// Önmagában csak a doboz; megnyitni a [showForetackDialog]-gal kell.
class ForetackDialog<T> extends StatelessWidget {
  /// Doboz a [title] címmel, a [message] magyarázattal és az [actions]
  /// akciókkal.
  const ForetackDialog({
    required this.title,
    required this.message,
    required this.actions,
    this.details = const [],
    this.maxWidth = defaultMaxWidth,
    super.key,
  });

  /// A phone dobozának szélessége (ADR 0047 E6); a web 480 px-et ad át.
  static const double defaultMaxWidth = 364;

  /// A doboz címe.
  final String title;

  /// A magyarázó szöveg: mi történik, és visszafordítható-e.
  final String message;

  /// Az érintett elem adatai; üresen az adatcella elmarad.
  final List<ForetackDialogDetail> details;

  /// Az akciók balról jobbra; a destruktív a végén áll (E6).
  final List<ForetackDialogAction<T>> actions;

  /// A doboz legnagyobb szélessége.
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initialFocus = actions.indexWhere((action) => !action.isDestructive);

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // A makett 11a címe; egyetlen helyen él, ezért nem
                // önálló tipográfiai fokozat (ADR 0044 D39).
                Text(
                  title,
                  style: supportTextStyle.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: supportTextStyle.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _DetailCell(details: details),
                ],
              ],
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: scheme.outlineVariant)),
            ),
            child: SizedBox(
              height: 52,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var index = 0; index < actions.length; index++)
                    Expanded(
                      child: _ActionCell<T>(
                        action: actions[index],
                        hasDividerBefore: index > 0,
                        isInitialFocus: index == initialFocus,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Megnyitja a [ForetackDialog]-ot, és visszaadja a választott akció
/// értékét; Esc vagy a háttérre kattintás esetén `null`-t.
Future<T?> showForetackDialog<T>({
  required BuildContext context,
  required String title,
  required String message,
  required List<ForetackDialogAction<T>> actions,
  List<ForetackDialogDetail> details = const [],
  double maxWidth = ForetackDialog.defaultMaxWidth,
}) {
  final scheme = Theme.of(context).colorScheme;
  return showDialog<T>(
    context: context,
    // A makett 11a scrimje: a felület sötétjénél is sötétebb, áttetsző.
    barrierColor: const Color(0xBD04070B),
    builder: (context) => Dialog(
      backgroundColor: scheme.surfaceContainer,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(side: BorderSide(color: scheme.outline)),
      child: ForetackDialog<T>(
        title: title,
        message: message,
        details: details,
        actions: actions,
        maxWidth: maxWidth,
      ),
    ),
  );
}

class _DetailCell extends StatelessWidget {
  const _DetailCell({required this.details});

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

class _ActionCell<T> extends StatelessWidget {
  const _ActionCell({
    required this.action,
    required this.hasDividerBefore,
    required this.isInitialFocus,
  });

  final ForetackDialogAction<T> action;
  final bool hasDividerBefore;
  final bool isInitialFocus;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: hasDividerBefore
            ? Border(left: BorderSide(color: scheme.outlineVariant))
            : null,
      ),
      child: InkWell(
        autofocus: isInitialFocus,
        onTap: () => Navigator.of(context).pop(action.value),
        hoverColor: scheme.surfaceContainerHigh,
        focusColor: scheme.surfaceContainerHigh,
        child: Center(
          child: Text(
            action.label,
            style: supportTextStyle.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: action.isDestructive ? scheme.error : scheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
