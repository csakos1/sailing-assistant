import 'dart:async';

import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:foretack_web/api/api_failure.dart';
import 'package:foretack_web/app/web_app_bar.dart';
import 'package:foretack_web/app/web_layout.dart';
import 'package:foretack_web/app/web_scroll_column.dart';
import 'package:foretack_web/l10n/web_localizations.dart';
import 'package:foretack_web/race_detail/detail_section_label.dart';
import 'package:foretack_web/race_detail/full_screen_track_map_screen.dart';
import 'package:foretack_web/race_detail/race_detail_providers.dart';
import 'package:foretack_web/race_detail/result_block.dart';
import 'package:foretack_web/race_edit/manual_race_editor_screen.dart';
import 'package:foretack_web/race_edit/result_editor_screen.dart';
import 'package:race_archive_api/race_archive_api.dart';

/// Egy verseny részletezője (ADR 0047 D8, ADR 0048 Addendum 4 K7–K10).
///
/// A napló sorára kattintva nyílik. A [raceName] a napló-sorból jön, hogy
/// az AppBar címe a betöltés alatt se legyen üres.
///
/// A `WebLocalizations.of(context)!` biztonságos: a `MaterialApp`
/// regisztrálja a delegátorokat.
class RaceDetailScreen extends ConsumerWidget {
  /// A [raceId] verseny részletezője.
  const RaceDetailScreen({
    required this.raceId,
    required this.raceName,
    super.key,
  });

  /// A verseny azonosítója.
  final String raceId;

  /// A verseny neve a napló-sorból.
  final String raceName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = WebLocalizations.of(context)!;
    final detail = ref.watch(raceDetailProvider(raceId));
    final loaded = detail.valueOrNull?.summary;
    final openEditor = loaded == null ? null : _editorOpener(context, loaded);

    return Scaffold(
      appBar: WebAppBar(
        // A betöltött név az átnevezés után is friss (K15).
        title: loaded?.name ?? raceName,
        showBack: true,
        actions: [
          if (openEditor != null)
            IconButton(
              tooltip: l10n.detailEditTooltip,
              icon: const Icon(Icons.edit_outlined),
              onPressed: openEditor,
            ),
        ],
      ),
      body: detail.when(
        skipLoadingOnRefresh: false,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _DetailError(
          message: _isNotFound(error)
              ? l10n.detailNotFound
              : l10n.detailLoadError,
          onRetry: _isNotFound(error)
              ? null
              : () => ref.invalidate(raceDetailProvider(raceId)),
        ),
        data: (detail) => _DetailBody(
          detail: detail,
          onEdit: _editorOpener(context, detail.summary),
        ),
      ),
    );
  }

  /// A verseny szerkesztőjét nyitó művelet (K15): telemetriásnál az
  /// eredmény-, kézinél a verseny-szerkesztő.
  static VoidCallback _editorOpener(
    BuildContext context,
    RaceSummary summary,
  ) =>
      () => unawaited(
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => switch (summary.origin) {
              TelemetryOrigin(:final recording) => ResultEditorScreen(
                summary: summary,
                recording: recording,
              ),
              ManualOrigin() => ManualRaceEditorScreen(summary: summary),
            },
          ),
        ),
      );

  static bool _isNotFound(Object error) =>
      error is ServerFailure && error.error is RaceNotFound;
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.detail, required this.onEdit});

  final RaceDetail detail;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = WebLocalizations.of(context)!;
    final summary = detail.summary;
    final telemetry = detail.telemetry;
    final legacyTrack = detail.legacyTrack;
    final stats = summary.stats;
    final summaryText = summary.result?.content.summary;

    return WebScrollColumn(
      bottomPadding: 56,
      children: [
        if (telemetry != null)
          DetailStatusStrip(race: telemetry.race)
        else
          _ManualStatusStrip(summary: summary),
        TrackStatsRow(stats: stats.track),
        RaceLogStatsStrip(cells: _windCells(l10n, stats)),
        if (stats.window.isApproximate) const _ApproximateNote(),
        ResultBlock(result: summary.result, onEdit: onEdit),
        if (telemetry != null) ...[
          const SizedBox(height: 24),
          _TrackMapCard(
            name: summary.name,
            trackPoints: telemetry.trackPoints,
            marks: telemetry.race.marks,
          ),
          DetailSectionLabel(text: l10n.detailMarksCaps),
          for (final mark in telemetry.race.marks) DetailMarkRow(mark: mark),
        ] else if (legacyTrack != null) ...[
          // A régi YDVR-track, bóják nélkül (ADR 0050 D7 + Addendum 2 F4).
          const SizedBox(height: 24),
          _TrackMapCard(
            name: summary.name,
            trackPoints: legacyTrack,
            marks: const [],
          ),
        ],
        if (summaryText != null) ...[
          DetailSectionLabel(text: l10n.detailSummaryCaps),
          Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: WebLayout.textMaxWidth,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: WebLayout.columnInset,
                ),
                child: Text(summaryText, style: supportTextStyle),
              ),
            ),
          ),
        ],
      ],
    );
  }

  List<RaceLogStatCell> _windCells(WebLocalizations l10n, RaceStats stats) {
    final windPoint = stats.windPoint;
    return [
      (label: l10n.detailWindAvgCaps, measured: measureKnots(stats.avgWindMps)),
      (label: l10n.detailWindMaxCaps, measured: measureKnots(stats.maxWindMps)),
      (
        label: l10n.detailWindDirectionCaps,
        measured: (
          value: windPoint == null
              ? missingValueLabel
              : compassPointLabel(windPoint),
          unit: '',
        ),
      ),
    ];
  }
}

/// A kézi verseny státusz-csíkja, a `DetailStatusStrip` geometriájával
/// (14m): balra a „KÉZI RÖGZÍTÉS", jobbra a verseny napja.
class _ManualStatusStrip extends StatelessWidget {
  const _ManualStatusStrip({required this.summary});

  final RaceSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = WebLocalizations.of(context)!;
    final uiL10n = ForetackUiLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final tones = Theme.of(context).extension<TextTones>()!;
    final dateLabel = switch (summary.origin) {
      ManualOrigin(:final date) =>
        uiL10n
            .detailFinishedDate(DateTime(date.year, date.month, date.day))
            .toUpperCase(),
      TelemetryOrigin() => '',
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 44,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: WebLayout.columnInset,
            ),
            child: Row(
              children: [
                Text(
                  l10n.detailManualCaps,
                  style: statusLabelStyle.copyWith(color: tones.low),
                ),
                const Spacer(),
                Text(
                  dateLabel,
                  style: numeralCaptionStyle.copyWith(color: tones.low),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 1, child: ColoredBox(color: scheme.outlineVariant)),
      ],
    );
  }
}

/// A közelítő-sor (K9): hivatalos idők nélkül a statok a teljes
/// rögzítésből számolódnak.
class _ApproximateNote extends StatelessWidget {
  const _ApproximateNote();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      WebLayout.columnInset,
      12,
      WebLayout.columnInset,
      0,
    ),
    child: Text(
      WebLocalizations.of(context)!.detailApproximate,
      // Ugyanaz a halk tónus, mint az üres eredmény sorában (K9, 13l).
      style: supportTextStyle.copyWith(
        color: Theme.of(context).extension<TextTones>()!.low,
      ),
    ),
  );
}

/// A gesztus nélküli térkép-kártya (K8); rákattintva a teljes képernyős
/// nézet nyílik. Üres tracknél nincs mit nagyítani, ezért nem kattintható.
/// A telemetriás és a régi track is ezt kapja; az utóbbi bóják nélkül.
class _TrackMapCard extends StatelessWidget {
  const _TrackMapCard({
    required this.name,
    required this.trackPoints,
    required this.marks,
  });

  final String name;
  final List<ArchiveTrackPoint> trackPoints;
  final List<Mark> marks;

  @override
  Widget build(BuildContext context) {
    final l10n = WebLocalizations.of(context)!;
    final points = [
      for (final point in trackPoints)
        TrackPoint(position: point.position, sogMps: point.sogMps),
    ];
    final map = TrackMap(
      points: points,
      marks: marks,
      emptyLabel: l10n.detailTrackEmpty,
      height: WebLayout.mapHeight,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: WebLayout.columnInset),
      child: points.isEmpty
          ? map
          : Tooltip(
              message: l10n.detailTrackOpenFullscreen,
              child: InkWell(
                onTap: () => unawaited(
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => FullScreenTrackMapScreen(
                        raceName: name,
                        points: points,
                        marks: marks,
                      ),
                    ),
                  ),
                ),
                // A FlutterMap kikapcsolt interakció mellett is elnyeli a
                // pointert, ezért kell az IgnorePointer (phone ADR 0036
                // F1-D2).
                child: IgnorePointer(child: map),
              ),
            ),
    );
  }
}

class _DetailError extends StatelessWidget {
  const _DetailError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = WebLocalizations.of(context)!;
    final retry = onRetry;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(WebLayout.columnInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, style: supportTextStyle, textAlign: TextAlign.center),
            if (retry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(onPressed: retry, child: Text(l10n.logRetryCaps)),
            ],
          ],
        ),
      ),
    );
  }
}
