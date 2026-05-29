import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:phone/app/confidence_colors.dart';

/// Három-szegmenses pont-indikátor a wind-shift confidence-hez (§8.7):
/// low `●○○`, medium `●●○`, high `●●●`. Shape + szín együtt (színvak-safe).
class ConfidenceDots extends StatelessWidget {
  /// A megjelenítendő confidence-szint.
  const ConfidenceDots(this.confidence, {super.key});

  /// A wind-shift trend megbízhatósága.
  final WindShiftConfidence confidence;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filled = switch (confidence) {
      WindShiftConfidence.low => 1,
      WindShiftConfidence.medium => 2,
      WindShiftConfidence.high => 3,
    };
    final color =
        theme.extension<ConfidenceColors>()?.forConfidence(confidence) ??
        theme.colorScheme.onSurface;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final isFilled = i < filled;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Icon(
            isFilled ? Icons.circle : Icons.circle_outlined,
            size: 8,
            color: isFilled ? color : color.withValues(alpha: 0.4),
          ),
        );
      }),
    );
  }
}
