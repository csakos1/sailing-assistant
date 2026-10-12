import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';

/// Egy stat az évsávon: verzál felirat, az érték a mértékegységgel, és
/// hogy még számolódik-e (akkor az érték tompa hiányjel).
typedef RaceLogBandStat = ({
  String label,
  MeasuredValue measured,
  bool isPending,
});

/// A Versenynapló évsávja a makett 35a szerint (a webes 7c, ADR 0048
/// Addendum 7 N1; ADR 0056 „Pontosítás (U8)").
///
/// Az évek fix, csökkenő sorrendben, a helyükön állnak: a kiválasztott a
/// helyén nagy számmal, a többi tompított, koppintható számként, alapvonalra
/// igazítva — maga az évsor a választó, mint a weben. A váltás 150 ms-os
/// animáció. Ha az évek nem férnek ki, a sor oldalra görgethető. Alatta a
/// versenyszám, a három stat és alul a 2 dp-s vonal; betöltés közben a
/// vonal helyén mozgó sáv fut (makett 35f).
///
/// A webes `RaceLogYearSelector`-tól azért külön widget, mert a telefonon
/// minden évnek 48 dp-s tapintási felület kell (a webé egérre szabott), és
/// a statok is a sávban állnak; a web így érintetlen marad.
///
/// A `TextTones` biztonságos: a `foretackTheme` regisztrálja.
class RaceLogYearBand extends StatelessWidget {
  /// Évsáv a [years] évekkel; a [selectedYear] áll nagyban. Betöltés
  /// közben ([selectedYear] `null`) a nagy szám helyén hiányjel áll.
  const RaceLogYearBand({
    required this.years,
    required this.selectedYear,
    required this.countLabel,
    required this.stats,
    this.onYearSelected,
    this.isLoading = false,
    super.key,
  });

  /// Az évek csökkenő sorrendben.
  final List<int> years;

  /// A kiválasztott év; `null`, amíg a napló töltődik.
  final int? selectedYear;

  /// A kiválasztott év versenyszámának kész, verzál felirata.
  final String countLabel;

  /// A három stat, balról jobbra.
  final List<RaceLogBandStat> stats;

  /// Egy másik év választása; a kiválasztott évre nem hívódik.
  final ValueChanged<int>? onYearSelected;

  /// Fut-e még számolás: ilyenkor a vonal helyén mozgó sáv áll.
  final bool isLoading;

  /// A méret- és színváltás hossza (a webes N1-gyel azonos).
  static const Duration transitionDuration = Duration(milliseconds: 150);

  /// A sáv alsó vonalának vastagsága.
  static const double bottomRuleHeight = 2;

  /// Az évsor felső betéte. A kiválasztott év saját 5 dp-s betétjével a
  /// szám doboza 17 dp-re van a sáv tetejétől; a Martian Mono számjegyei a
  /// dobozuk tetejénél pár dp-vel lejjebb kezdődnek, így a szám teteje
  /// ugyanakkora (~20 dp) résre esik a sáv tetejétől, mint a stat-sor alja
  /// (20 dp betét) a sáv aljától: a tartalom függőlegesen középen áll (UF).
  static const double topInset = 12;

  // A betöltés alatti nagy szám helyén álló hiányjel (makett 35f).
  static const String _pendingYear = '––––';

  static const TextStyle _countStyle = TextStyle(
    fontFamily: numeralFontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tones = Theme.of(context).extension<TextTones>()!;
    final selected = selectedYear;
    final select = onYearSelected;

    return ColoredBox(
      color: scheme.surfaceContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            // Az évek saját vízszintes betéte (_YearButton) adja ki a 20 dp-s
            // margót, így a szám a makett szerinti helyen áll.
            padding: const EdgeInsets.fromLTRB(
              20 - _YearButton.horizontalInset,
              topInset,
              20 - _YearButton.horizontalInset,
              0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                if (selected == null)
                  const _YearButton(
                    label: _pendingYear,
                    isSelected: true,
                    isPending: true,
                  )
                else
                  for (final year in years)
                    _YearButton(
                      label: '$year',
                      isSelected: year == selected,
                      onTap: year == selected || select == null
                          ? null
                          : () => select(year),
                    ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(countLabel, style: _countStyle.copyWith(color: tones.low)),
                const SizedBox(height: 20),
                // Nagy betűméretnél vagy keskeny kijelzőn kicsinyít, sosem
                // csordul túl.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final (index, stat) in stats.indexed) ...[
                          if (index > 0) ...[
                            const SizedBox(width: 22),
                            SizedBox(
                              width: 1,
                              child: ColoredBox(color: scheme.outline),
                            ),
                            const SizedBox(width: 22),
                          ],
                          _BandStat(stat: stat),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isLoading)
            LinearProgressIndicator(
              minHeight: bottomRuleHeight,
              color: scheme.onSurfaceVariant,
              backgroundColor: scheme.outline,
            )
          else
            SizedBox(
              height: bottomRuleHeight,
              child: ColoredBox(color: scheme.outline),
            ),
        ],
      ),
    );
  }
}

/// Egy év a sávon: kiválasztva nagy és világos, különben tompított és
/// koppintható. A függőleges betét a 48 dp-s tapintási felületet adja.
class _YearButton extends StatelessWidget {
  const _YearButton({
    required this.label,
    required this.isSelected,
    this.isPending = false,
    this.onTap,
  });

  /// Az évek közti rés fele (14 dp-s rés két szomszéd között).
  static const double horizontalInset = 7;

  final String label;
  final bool isSelected;

  /// Betöltés alatti hiányjel: tompa színnel.
  final bool isPending;

  final VoidCallback? onTap;

  static const TextStyle _selectedStyle = TextStyle(
    fontFamily: numeralFontFamily,
    fontSize: 38,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.76,
    height: 1,
  );

  static const TextStyle _otherStyle = TextStyle(
    fontFamily: numeralFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1,
  );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tones = Theme.of(context).extension<TextTones>()!;
    final style = isSelected
        ? _selectedStyle.copyWith(
            color: isPending ? scheme.outline : scheme.onSurface,
          )
        : _otherStyle.copyWith(color: tones.low);

    return Semantics(
      button: onTap != null,
      selected: isSelected,
      child: InkWell(
        onTap: onTap,
        // A kiemelést a szín adja, nem a Material-réteg (mint a weben).
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        child: AnimatedPadding(
          duration: RaceLogYearBand.transitionDuration,
          curve: Curves.easeOut,
          // A nagy szám mellett 18 dp a rés (7c): 2 dp-vel több oldalanként.
          // Függőlegesen a tapintási felület legalább 48 dp.
          padding: isSelected
              ? const EdgeInsets.fromLTRB(
                  horizontalInset + 2,
                  5,
                  horizontalInset + 2,
                  5,
                )
              : const EdgeInsets.symmetric(
                  horizontal: horizontalInset,
                  vertical: 17,
                ),
          child: AnimatedDefaultTextStyle(
            duration: RaceLogYearBand.transitionDuration,
            curve: Curves.easeOut,
            style: style,
            child: Text(label),
          ),
        ),
      ),
    );
  }
}

/// Egy stat a sávon: az érték a mértékegységgel, alatta a felirat.
class _BandStat extends StatelessWidget {
  const _BandStat({required this.stat});

  final RaceLogBandStat stat;

  static const TextStyle _valueStyle = TextStyle(
    fontFamily: numeralFontFamily,
    fontSize: 21,
    fontWeight: FontWeight.w700,
    height: 1,
  );

  static const TextStyle _unitStyle = TextStyle(
    fontFamily: numeralFontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w500,
  );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tones = Theme.of(context).extension<TextTones>()!;
    final measured = stat.measured;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 5,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          spacing: 3,
          children: [
            Text(
              measured.value,
              style: _valueStyle.copyWith(
                color: stat.isPending ? scheme.outline : scheme.onSurface,
              ),
            ),
            // Hiányzó mérésnél nincs mértékegység.
            if (measured.unit.isNotEmpty)
              Text(measured.unit, style: _unitStyle.copyWith(color: tones.low)),
          ],
        ),
        Text(
          stat.label,
          style: railLabelStyle.copyWith(
            fontSize: 9,
            letterSpacing: 0.9,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
