import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:phone/providers/raw_nmea_connection_status_provider.dart';
import 'package:phone/providers/raw_nmea_lines_provider.dart';

/// A Fázis 3 debug képernyő: a TCP kapcsolat-állapotot és a beérkező nyers
/// NMEA sorokat mutatja real-time.
///
/// A sorrend tudatosan **legújabb felül** — egy debug-viewerben az utolsó
/// érkezett sor a fontos, és nem akarunk auto-scroll bonyodalmat (Fázis 3
/// scope: csontváz + viewer, semmi több, ADR 0006). Az `AppLocalizations.of`
/// `!`-ja biztonságos: a fenti `MaterialApp` regisztrálja a delegátorokat.
class RawNmeaViewerScreen extends ConsumerWidget {
  const RawNmeaViewerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final status = ref.watch(rawNmeaConnectionStatusProvider);
    final lines = ref.watch(rawNmeaLinesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.viewerTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _ConnectionStatusChip(status: status),
          ),
        ],
      ),
      body: lines.isEmpty
          ? Center(child: Text(l10n.viewerEmptyState))
          : ListView.builder(
              itemCount: lines.length,
              itemBuilder: (context, index) {
                // Legújabb felül: a state utolsó eleme jelenik meg elsőként.
                final line = lines[lines.length - 1 - index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 2,
                  ),
                  child: Text(
                    line,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _ConnectionStatusChip extends StatelessWidget {
  const _ConnectionStatusChip({required this.status});

  final ConnectionStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Sealed switch expression a négy ConnectionStatus-altípusra. A label, a
    // szín és az opcionális tooltip együtt landol egy rekordban — nincs
    // felesleges null-check, és a fordító kikényszeríti a teljességet (új
    // altípus esetén compile-error).
    final (label, color, tooltip) = switch (status) {
      Connecting() => (l10n.statusConnecting, Colors.orange.shade700, null),
      Connected() => (l10n.statusConnected, Colors.green.shade700, null),
      Disconnected() => (l10n.statusDisconnected, Colors.grey.shade700, null),
      ConnectionError(:final message) => (
        l10n.statusError(message),
        Colors.red.shade700,
        message,
      ),
    };

    final chip = Chip(
      label: Text(label),
      labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
      backgroundColor: color,
    );
    return tooltip != null ? Tooltip(message: tooltip, child: chip) : chip;
  }
}
