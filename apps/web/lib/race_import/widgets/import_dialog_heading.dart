import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';

/// A feltöltés-dialógus címsora (makett 13f–13j): a cím, jobbra a
/// haladás (`62 %`, FELDOLGOZÁS) vagy egy státusznégyzet.
class ImportDialogHeading extends StatelessWidget {
  /// Címsor a [title] címmel és az opcionális [trailing] elemmel.
  const ImportDialogHeading({required this.title, this.trailing, super.key});

  /// A dialógus címe.
  final String title;

  /// A jobb szélen álló elem.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final trailing = this.trailing;
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            // A `ForetackDialog` címének fokozata (11a); egyetlen helyen él,
            // ezért nem önálló tipográfiai fokozat (ADR 0044 D39).
            style: supportTextStyle.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 12), trailing],
      ],
    );
  }
}
