import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:phone/app/foretack_typography.dart';
import 'package:phone/app/text_tones.dart';
import 'package:phone/app/true_time.dart';
import 'package:phone/app/warning_colors.dart';
import 'package:phone/features/live_race/live_formatters.dart';
import 'package:phone/l10n/app_localizations.dart';

/// Az élő képernyő státuszsora (§8.7, ADR 0042 D10): kapcsolat-jelző, aktív
/// bója neve, GPS-idő (true-time forrás, ADR 0012), és — ha az adat elavult
/// — egy „ELAVULT" chip.
///
/// Fix 34 dp magas, fent és lent 1 dp hairline határolja: az 1c elrendezésben
/// ez választja el a rácstól, nem a margó.
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
    final scheme = theme.colorScheme;
    // A foretackTheme mindkét extensiont regisztrálja.
    final tones = theme.extension<TextTones>()!;
    final warningColors = theme.extension<WarningColors>()!;
    final l10n = AppLocalizations.of(context)!;
    final (label, color) = _connection(
      connectionStatus,
      l10n,
      scheme,
      warningColors,
      tones,
    );

    // wallClockUnsynced → explicit „nem szinkronizált" jel: `~` prefix +
    // tompított szín (ADR 0012 D6). gnss/sessionAnchor → sima idő.
    final unsynced = trueTime.source == TrueTimeSource.wallClockUnsynced;
    final timeText = formatInstrumentTime(trueTime.utc);

    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, size: 9, color: color),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: supportTextStyle.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          if (isStale) ...[
            _StaleChip(label: l10n.liveStale, color: warningColors.warning),
            const SizedBox(width: 10),
          ],
          Text(
            markName ?? missingValue,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: supportTextStyle.copyWith(color: scheme.onSurface),
          ),
          const SizedBox(width: 12),
          Text(
            unsynced ? '~$timeText' : timeText,
            style: instrumentClockStyle.copyWith(
              color: unsynced ? tones.low : scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  // A kapcsolat-jelző SOHA nem zöld: a zöld a terméken kizárólag starboardot
  // jelent, és ugyanezen a képernyőn ott vannak a starboard nyilak
  // (ADR 0042 D10).
  (String, Color) _connection(
    ConnectionStatus status,
    AppLocalizations l10n,
    ColorScheme scheme,
    WarningColors warningColors,
    TextTones tones,
  ) => switch (status) {
    Connecting() => (l10n.statusConnecting, warningColors.warning),
    Connected() => (l10n.statusConnected, scheme.primary),
    Disconnected() => (l10n.statusDisconnected, tones.low),
    ConnectionError(:final message) => (
      l10n.statusError(message),
      warningColors.critical,
    ),
  };
}

/// Az „elavult adat" chip a státuszsorban (ADR 0042 D12).
///
/// Kontúros pill, nem tömör doboz: az elavulás **nem** riasztás — az értékek
/// megmaradnak a képernyőn, csak a koruk kérdéses —, ezért a jelzés a
/// warning-tokent viszi, de nem foglal el hátteret a státuszsorban.
class _StaleChip extends StatelessWidget {
  const _StaleChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      border: Border.all(color: color),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.schedule, size: 11, color: color),
        const SizedBox(width: 4),
        Text(label, style: sectionLabelStyle.copyWith(color: color)),
      ],
    ),
  );
}
