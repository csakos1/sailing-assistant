import 'package:flutter/material.dart';

/// A feltöltés 2 px-es sávja a doboz tetején (ADR 0047 E6, makett 13h).
///
/// Saját rajz a `LinearProgressIndicator` helyett: annak az M3-as alakja
/// (lekerekítés, rés, végpont-jelölő) eltérne a makett egyenes vonalától.
class ImportProgressLine extends StatelessWidget {
  /// Sáv a [fraction] (0–1) haladással.
  const ImportProgressLine({required this.fraction, super.key});

  /// A haladás 0 és 1 között.
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 2,
      child: ColoredBox(
        color: scheme.outlineVariant,
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: fraction.clamp(0, 1).toDouble(),
            child: ColoredBox(color: scheme.onSurface),
          ),
        ),
      ),
    );
  }
}
