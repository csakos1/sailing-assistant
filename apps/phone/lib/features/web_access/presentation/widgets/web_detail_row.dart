import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';

/// Egy adatsor a webes hozzáférés képernyőin: címke balra, mono érték
/// jobbra, alatta hairline (makett 18f, 18e-2).
class WebDetailRow extends StatelessWidget {
  /// Sor a [label] címkével és a [value] értékkel.
  const WebDetailRow({required this.label, required this.value, super.key});

  /// A címke.
  final String label;

  /// A monóval írt érték.
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          spacing: 16,
          children: [
            Text(
              label,
              style: supportTextStyle.copyWith(color: scheme.onSurfaceVariant),
            ),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
                style: numeralMicroStyle.copyWith(color: scheme.onSurface),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
