import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:phone/app/true_time.dart';
import 'package:phone/features/live_race/live_formatters.dart';
import 'package:phone/l10n/app_localizations.dart';

/// Az élő képernyő státuszsora (§8.7): kapcsolat-jelző, aktív bója neve,
/// GPS-idő (true-time forrás, ADR 0012), és — ha az adat elavult — egy
/// „elavult" chip.
///
/// „Dumb" widget: a nyers értékeket kapja, az l10n-t a kontextusból olvassa
/// (az `AppLocalizations.of` `!`-ja biztonságos a `MaterialApp` alatt).
class LiveStatusBar extends StatelessWidget {
  /// A státuszsor bemenetei.
  const LiveStatusBar({
    required this.connectionStatus,
    required this.markName,
    required this.trueTime,
    required this.isStale,
    super.key,
  });

  /// A TCP-kapcsolat állapota.
  final ConnectionStatus connectionStatus;

  /// Az aktív bója neve, vagy null (`—`).
  final String? markName;

  /// A megjelenítendő GPS-idő olvasata (true-time + megbízhatóság, ADR 0012).
  final TrueTimeReading trueTime;

  /// Igaz, ha csatlakozott állapotban az adat túl régi.
  final bool isStale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final (label, color) = _connection(connectionStatus, l10n);

    // wallClockUnsynced → explicit „nem szinkronizált" jel: `~` prefix +
    // tompított szín (ADR 0012 D6). gnss/sessionAnchor → sima idő.
    final unsynced = trueTime.source == TrueTimeSource.wallClockUnsynced;
    final timeText = formatInstrumentTime(trueTime.utc);

    return Row(
      children: [
        Icon(Icons.circle, size: 10, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
        ),
        if (isStale) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              l10n.liveStale,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Text(markName ?? missingValue, style: theme.textTheme.bodyMedium),
        const SizedBox(width: 12),
        Text(
          unsynced ? '~$timeText' : timeText,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
            color: unsynced ? theme.colorScheme.onSurfaceVariant : null,
          ),
        ),
      ],
    );
  }

  (String, Color) _connection(ConnectionStatus status, AppLocalizations l10n) =>
      switch (status) {
        Connecting() => (l10n.statusConnecting, Colors.orange.shade700),
        Connected() => (l10n.statusConnected, Colors.green.shade700),
        Disconnected() => (l10n.statusDisconnected, Colors.grey.shade600),
        ConnectionError(:final message) => (
          l10n.statusError(message),
          Colors.red.shade700,
        ),
      };
}
