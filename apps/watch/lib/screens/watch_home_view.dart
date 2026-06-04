import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:watch/theme/watch_colors.dart';
import 'package:watch/watch_sync/watch_state_provider.dart';

/// Az óra v1 minimál élő nézete: a telefon `WatchPayload`-jának értékeit
/// rendereli a sötét témában. A polírozott A/B nézet, a nyilak, a perem-nav
/// és az ambient az f3b-3; itt a cél, hogy az adat helyesen megjelenjen
/// (7-bg-g sanity). Az előjeles szögeket magnitúdóként mutatja (az előjelet a
/// nyíl hordozza majd az f3b-3-ban); a számokat a `shared` formázói adják.
class WatchHomeView extends ConsumerWidget {
  /// Létrehozza a nézetet.
  const WatchHomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // A watchDarkTheme mindig regisztrálja a WatchColors-t, ezért a `!` itt
    // nem fut null-ra.
    final colors = Theme.of(context).extension<WatchColors>()!;
    final state = ref.watch(watchStateProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: state.when(
            loading: () => CircularProgressIndicator(color: colors.signal),
            error: (error, _) =>
                Text('Nincs adat', style: TextStyle(color: colors.critical)),
            data: (payload) => _PayloadBody(payload: payload, colors: colors),
          ),
        ),
      ),
    );
  }
}

class _PayloadBody extends StatelessWidget {
  const _PayloadBody({required this.payload, required this.colors});

  final WatchPayload payload;
  final WatchColors colors;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _GpsTime(payload: payload, colors: colors),
          const SizedBox(height: 8),
          _Metric(
            label: 'SOG (kts)',
            value: formatSpeedKnots(payload.sogKnots),
            colors: colors,
          ),
          _Metric(
            label: 'TWA',
            value: formatDegreesMagnitude(payload.currentTwa),
            colors: colors,
          ),
          _Metric(
            label: 'TWA bója',
            value: formatDegreesMagnitude(payload.predictedTwaAtMark),
            colors: colors,
          ),
          _Metric(
            label: 'Korrekció',
            value: formatDegreesMagnitude(payload.courseCorrection),
            colors: colors,
          ),
          _Metric(
            label: 'ETA',
            value: formatEtaSeconds(payload.etaSeconds, minutesUnit: 'perc'),
            colors: colors,
          ),
          _Metric(
            label: 'Bója táv',
            value: formatDistanceMeters(payload.distanceMeters),
            colors: colors,
          ),
          _Metric(
            label: 'Bója',
            value: payload.markName ?? missingValue,
            colors: colors,
          ),
          if (payload.criticalWarnings.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final warning in payload.criticalWarnings)
              Text(
                warning,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.critical),
              ),
          ],
        ],
      ),
    );
  }
}

class _GpsTime extends StatelessWidget {
  const _GpsTime({required this.payload, required this.colors});

  final WatchPayload payload;
  final WatchColors colors;

  @override
  Widget build(BuildContext context) {
    final dotColor = payload.isGpsTimeTrusted
        ? colors.signal
        : colors.textTertiary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          formatLocalClock(payload.gpsTimeUtc),
          style: TextStyle(
            color: colors.text,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.colors,
  });

  final String label;
  final String value;
  final WatchColors colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(color: colors.textSecondary, fontSize: 11),
          ),
          Text(
            value,
            style: TextStyle(
              color: colors.text,
              fontSize: 28,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
