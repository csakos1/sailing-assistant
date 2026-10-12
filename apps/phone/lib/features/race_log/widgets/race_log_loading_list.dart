import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/l10n/app_localizations.dart';

/// A napló listájának betöltés alatti váza (makett 35f).
///
/// Egy „BETÖLTÉS" fejléc egy lassan forgó, szögletes jellel, alatta a mai
/// napló-sorok méretében tompa vázak: „––" nap és egy sáv a név helyén. Nincs
/// középre tett kör-spinner és nincs shimmer; az utolsó sor halványabb, hogy
/// a lista ne érjen véget élesen.
///
/// Az `AppLocalizations.of(context)!` és a `TextTones` biztonságos: a
/// `MaterialApp` és a `foretackTheme` regisztrálja őket.
class RaceLogLoadingList extends StatelessWidget {
  /// A napló-lista váza.
  const RaceLogLoadingList({super.key});

  /// A váz-sorok szélessége a név helyén, a makett arányai szerint.
  static const List<double> rowWidthFactors = [
    0.58,
    0.40,
    0.72,
    0.48,
    0.36,
    0.64,
    0.52,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tones = Theme.of(context).extension<TextTones>()!;

    return ListView(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        Padding(
          // A `RaceLogMonthHeader` betétje: a fejléc a helyén vált.
          padding: const EdgeInsets.fromLTRB(16, 24, 20, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.logLoadingCaps,
                  style: sectionLabelStyle.copyWith(color: tones.low),
                ),
              ),
              const _SquareSpinner(),
            ],
          ),
        ),
        for (final (index, factor) in rowWidthFactors.indexed)
          Opacity(
            opacity: index == rowWidthFactors.length - 1 ? 0.55 : 1,
            child: _SkeletonRow(widthFactor: factor),
          ),
      ],
    );
  }
}

/// Egy váz-sor a `RaceLogRow` geometriájával: 56 dp, 16 + 28 + 16 dp-s
/// nap-oszlop, alatta hairline.
class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow({required this.widthFactor});

  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 56,
          child: Row(
            children: [
              const SizedBox(width: 16),
              SizedBox(
                width: 28,
                child: Center(
                  child: Text(
                    '––',
                    style: numeralMicroStyle.copyWith(color: scheme.outline),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: widthFactor,
                    child: SizedBox(
                      height: 11,
                      child: ColoredBox(color: scheme.surfaceContainerHigh),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 52),
            ],
          ),
        ),
        SizedBox(height: 1, child: ColoredBox(color: scheme.outlineVariant)),
      ],
    );
  }
}

/// A „BETÖLTÉS" fejléc szögletes, lassan forgó jele (makett 35f).
class _SquareSpinner extends StatefulWidget {
  const _SquareSpinner();

  @override
  State<_SquareSpinner> createState() => _SquareSpinnerState();
}

class _SquareSpinnerState extends State<_SquareSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _rotation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return RotationTransition(
      turns: _rotation,
      child: SizedBox.square(
        dimension: 12,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: scheme.outline, width: 1.5),
          ),
        ),
      ),
    );
  }
}
