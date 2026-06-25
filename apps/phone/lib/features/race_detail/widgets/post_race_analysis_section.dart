import 'dart:math' as math;

import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/app/marine_colors.dart';
import 'package:phone/features/race_detail/post_race_analysis.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:phone/providers/post_race_analysis_provider.dart';

/// Hianyzo ertek jele a debug-szekcioban.
const _kMissing = '—';

/// Debug-only post-race elemzes szekcio a verseny-detailen (ADR 0034 D6).
///
/// A befejezett verseny rogzitett pillanatkepeibol szamolt moat-metrikakat
/// mutatja: osszegzo fej (atlag |delta|, savon-belul arany, atlag lead) +
/// megkerulesenkenti kartyak (A-savvizualizacio + nyers szamok a
/// megbizhatosagi ablakkal). Csak `kDebugMode`-ban es `finished` versenyen
/// jelenik meg (a `RaceDetailScreen` gateli); a provider autoDispose.
class PostRaceAnalysisSection extends ConsumerWidget {
  /// A szekcio a [raceId]-hoz tartozo elemzest jeleniti meg.
  const PostRaceAnalysisSection({required this.raceId, super.key});

  /// A befejezett verseny azonositoja (a provider-family kulcsa).
  final String raceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final analysis = ref.watch(postRaceAnalysisProvider(raceId));

    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.detailAnalysisTitle,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          analysis.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => Text(l10n.detailAnalysisError, style: muted),
            data: (data) => data.isEmpty
                ? Text(l10n.detailAnalysisEmpty, style: muted)
                : _AnalysisBody(data: data, l10n: l10n),
          ),
        ],
      ),
    );
  }
}

/// Az elemzes torzse: osszegzo fej + megkereles-kartyak.
class _AnalysisBody extends StatelessWidget {
  const _AnalysisBody({required this.data, required this.l10n});

  final PostRaceAnalysis data;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SummaryHeader(summary: data.summary, l10n: l10n),
        const SizedBox(height: 12),
        for (final result in data.roundings) ...[
          _RoundingCard(result: result, l10n: l10n),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

/// Harom metric-cella: atlag |delta|, savon-belul arany, atlag lead.
class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({required this.summary, required this.l10n});

  final RoundingSummary summary;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final avgDelta = summary.avgAbsDeltaDeg;
    final bandValue = summary.bandTotal == 0
        ? _kMissing
        : '${summary.bandHits}/${summary.bandTotal}';

    return Row(
      children: [
        Expanded(
          child: _SummaryCell(
            label: l10n.detailAnalysisAvgDelta,
            value: avgDelta == null
                ? _kMissing
                : '${avgDelta.toStringAsFixed(1)}°',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryCell(
            label: l10n.detailAnalysisBandRatio,
            value: bandValue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryCell(
            label: l10n.detailAnalysisAvgLead,
            value: _formatMinSec(summary.avgLeadTime),
          ),
        ),
      ],
    );
  }
}

/// Egy osszegzo cella: nagy ertek + halvany cimke alatta.
class _SummaryCell extends StatelessWidget {
  const _SummaryCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Egy megkereles kartyaja: from->to fejlec + A-sav + nyers szamok.
class _RoundingCard extends StatelessWidget {
  const _RoundingCard({required this.result, required this.l10n});

  final RoundingResult result;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final delta = result.deltaDeg;
    final band = result.forecastBandDeg;
    final within = result.isWithinBand;
    final hasBar = delta != null && band != null;

    final deltaColor = within == null
        ? theme.colorScheme.onSurfaceVariant
        : (within ? starboardColor : portColor);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${result.fromMark} → ${result.toMark}',
                  style: theme.textTheme.titleSmall,
                ),
              ),
              Text(
                _formatSignedDeg(delta),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: deltaColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (hasBar) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 30,
              child: CustomPaint(
                painter: _BandBarPainter(
                  deltaDeg: delta,
                  bandDeg: band,
                  withinColor: starboardColor,
                  outsideColor: portColor,
                  trackColor: theme.colorScheme.outlineVariant,
                  zoneColor: theme.colorScheme.onSurface.withValues(
                    alpha: 0.06,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          _RawNumbers(result: result, l10n: l10n),
        ],
      ),
    );
  }
}

/// A nyers szamok: josolt/tenyleges TWA + a megbizhatosagi ablak.
class _RawNumbers extends StatelessWidget {
  const _RawNumbers({required this.result, required this.l10n});

  final RoundingResult result;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    final predictedDeg = _formatDegMag(result.predictedTwaDeg);
    final actualDeg = _formatDegMag(result.actualTwaDeg);

    final lead = result.leadTime;
    final window = lead == null
        ? _kMissing
        : '${_formatMinSec(lead)} → '
              '${_formatMinSec(result.lastReliableLeadTime)} '
              '${l10n.detailAnalysisBeforeMark}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${l10n.detailAnalysisPredicted} $predictedDeg'
          '  ·  ${l10n.detailAnalysisActual} $actualDeg',
          style: muted,
        ),
        const SizedBox(height: 2),
        Text('${l10n.detailAnalysisReliable}: $window', style: muted),
      ],
    );
  }
}

/// A-variansu savvizualizacio: kozepre helyezett zona + jelolo pont. A
/// jelolo savon belul zold, kivul piros + a sav-szeltol a jeloloig huzott
/// tullovesszakasz (ADR 0034 D6).
class _BandBarPainter extends CustomPainter {
  _BandBarPainter({
    required this.deltaDeg,
    required this.bandDeg,
    required this.withinColor,
    required this.outsideColor,
    required this.trackColor,
    required this.zoneColor,
  });

  final double deltaDeg;
  final double bandDeg;
  final Color withinColor;
  final Color outsideColor;
  final Color trackColor;
  final Color zoneColor;

  @override
  void paint(Canvas canvas, Size size) {
    const pad = 12.0;
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final deltaAbs = deltaDeg.abs();
    final within = deltaAbs <= bandDeg;

    // A lathato fel-tartomany: a sav legyen ertelmes zona, a jelolo lassek.
    final halfRange = math.max(bandDeg * 2.5, math.max(deltaAbs * 1.2, 10));
    final pxPerDeg = (size.width / 2 - pad) / halfRange;
    final markerX = (centerX + deltaDeg * pxPerDeg).clamp(
      pad,
      size.width - pad,
    );
    final bandHalfPx = bandDeg * pxPerDeg;

    canvas.drawLine(
      Offset(pad, centerY),
      Offset(size.width - pad, centerY),
      Paint()
        ..color = trackColor
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    // A zona (a hibasav) halvany kitoltessel + konturral.
    final zoneRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(
        centerX - bandHalfPx,
        centerY - 9,
        centerX + bandHalfPx,
        centerY + 9,
      ),
      const Radius.circular(4),
    );
    canvas
      ..drawRRect(zoneRect, Paint()..color = zoneColor)
      ..drawRRect(
        zoneRect,
        Paint()
          ..color = trackColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );

    // Tulloves: a sav-szeltol a jeloloig piros szakasz (csak savon kivul).
    if (!within) {
      final edgeX = centerX + bandDeg * deltaDeg.sign * pxPerDeg;
      canvas.drawLine(
        Offset(edgeX, centerY),
        Offset(markerX, centerY),
        Paint()
          ..color = outsideColor
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }

    // Kozeptengely (delta=0) + jelolo pont (belul zold, kivul piros).
    canvas
      ..drawLine(
        Offset(centerX, centerY - 10),
        Offset(centerX, centerY + 10),
        Paint()
          ..color = trackColor
          ..strokeWidth = 1,
      )
      ..drawCircle(
        Offset(markerX, centerY),
        5.5,
        Paint()..color = within ? withinColor : outsideColor,
      );
  }

  @override
  bool shouldRepaint(_BandBarPainter oldDelegate) =>
      oldDelegate.deltaDeg != deltaDeg ||
      oldDelegate.bandDeg != bandDeg ||
      oldDelegate.withinColor != withinColor ||
      oldDelegate.outsideColor != outsideColor ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.zoneColor != zoneColor;
}

/// Egy fok-ertek elojeles alakja egesz fokra kerekitve (`+3°` / `-17°`),
/// vagy a hianyjel.
String _formatSignedDeg(double? value) {
  if (value == null) return _kMissing;
  final rounded = value.round();
  return rounded > 0 ? '+$rounded°' : '$rounded°';
}

/// Egy TWA-ertek magnitudoja egesz fokra kerekitve (`120°`), vagy a hianyjel.
String _formatDegMag(double? value) =>
    value == null ? _kMissing : '${value.abs().round()}°';

/// Egy idotartam `m:ss` alakja (`5:34`), vagy a hianyjel.
String _formatMinSec(Duration? duration) {
  if (duration == null) return _kMissing;
  final minutes = duration.inMinutes;
  final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
