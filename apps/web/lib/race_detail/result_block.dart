import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:foretack_web/app/web_layout.dart';
import 'package:foretack_web/l10n/web_localizations.dart';
import 'package:foretack_web/race_detail/detail_formatters.dart';
import 'package:foretack_web/race_detail/detail_section_label.dart';
import 'package:race_archive_api/race_archive_api.dart';

/// Az eredmény-blokk a részletezőn (ADR 0048 Addendum 4 K10).
///
/// Két közös csík (helyezések, adatok) és a díj. Csak a kitöltött cellák
/// jelennek meg; ha egy csíknak nem maradna cellája, a csík elmarad. Üres
/// eredménynél a 13l halk sora áll a helyén; ha van [onEdit], a sor a
/// szerkesztőt nyitja (ADR 0048 Addendum 4 K14).
///
/// A `WebLocalizations.of(context)!` és a `TextTones` biztonságos: a
/// `MaterialApp` és a `foretackTheme` regisztrálja őket.
class ResultBlock extends StatelessWidget {
  /// Blokk a [result] eredménnyel; `null`, ha nincs rögzítve.
  const ResultBlock({required this.result, this.onEdit, super.key});

  /// A verseny eredménye.
  final RaceResult? result;

  /// A szerkesztő megnyitása az üres eredmény sorából.
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = WebLocalizations.of(context)!;
    final tones = Theme.of(context).extension<TextTones>()!;
    final content = result?.content;
    final placings = content == null
        ? const <RaceLogStatCell>[]
        : _placings(l10n, content);
    final data = content == null
        ? const <RaceLogStatCell>[]
        : _data(l10n, content);
    final prize = content?.prize;
    // Csak összefoglalót tartalmazó eredménynél sincs mit mutatni a blokkban.
    final isEmpty = placings.isEmpty && data.isEmpty && prize == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DetailSectionLabel(text: l10n.detailResultCaps),
        if (isEmpty)
          InkWell(
            onTap: onEdit,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                WebLayout.columnInset,
                0,
                WebLayout.columnInset,
                8,
              ),
              child: Text(
                l10n.detailNoResult,
                style: supportTextStyle.copyWith(color: tones.low),
              ),
            ),
          ),
        if (placings.isNotEmpty) RaceLogStatsStrip(cells: placings),
        if (data.isNotEmpty) RaceLogStatsStrip(cells: data),
        if (prize != null) ...[
          DetailSectionLabel(text: l10n.detailPrizeCaps),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: WebLayout.columnInset,
            ),
            child: Text(prize, style: supportTextStyle),
          ),
        ],
      ],
    );
  }

  List<RaceLogStatCell> _placings(
    WebLocalizations l10n,
    RaceResultInput content,
  ) => [
    if (content.classPlace case final placing?)
      (
        label: l10n.detailClassPlaceCaps,
        measured: _placingValue(placing, content.classFleetSize),
      ),
    if (content.overallPlace case final placing?)
      (
        label: l10n.detailOverallPlaceCaps,
        measured: _placingValue(placing, content.overallFleetSize),
      ),
    if (content.monohullPlace case final placing?)
      (
        label: l10n.detailMonohullPlaceCaps,
        measured: _placingValue(placing, content.monohullFleetSize),
      ),
  ];

  List<RaceLogStatCell> _data(WebLocalizations l10n, RaceResultInput content) {
    final start = content.officialStart;
    final finish = content.officialFinish;
    final elapsed = content.officialElapsed;
    return [
      if (content.ysNumberHundredths case final ys?)
        (
          label: l10n.detailYsCaps,
          measured: (value: formatYsNumber(ys), unit: ''),
        ),
      if (start != null)
        (
          label: l10n.detailOfficialStartCaps,
          measured: (value: formatLocalClock(start), unit: ''),
        ),
      if (finish != null)
        (
          label: l10n.detailOfficialFinishCaps,
          measured: (
            value: formatLocalClock(finish),
            unit: start != null && isNextLocalDay(start, finish)
                ? l10n.detailNextDayCaps
                : '',
          ),
        ),
      if (elapsed != null && elapsed > Duration.zero)
        (
          label: l10n.detailElapsedCaps,
          measured: (value: formatElapsed(elapsed), unit: ''),
        ),
    ];
  }
}

/// Egy helyezés értéke: `3` + `/ 24`, mezőny nélkül `1.`, feladásnál
/// `DNF` + `/ 56` (Addendum 1 G3).
MeasuredValue _placingValue(Placing placing, int? fleetSize) {
  final fleet = fleetSize == null ? '' : '/ $fleetSize';
  return switch (placing) {
    FinishPlace(:final place) when fleetSize == null => (
      value: '$place.',
      unit: '',
    ),
    FinishPlace(:final place) => (value: '$place', unit: fleet),
    Dnf() => (value: 'DNF', unit: fleet),
    Dsq() => (value: 'DSQ', unit: fleet),
  };
}
