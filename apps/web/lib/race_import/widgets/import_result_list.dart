import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:foretack_web/l10n/web_localizations.dart';
import 'package:foretack_web/race_import/import_result_groups.dart';

/// Az import eredménye csoportonként (ADR 0048 Addendum 4 K21, makett
/// 13i).
///
/// A csoport-fejléc a napló hónap-fejléce, jobbra a darabszámmal. A törzs
/// legfeljebb 320 px magas, fölötte görget.
class ImportResultList extends StatelessWidget {
  /// Lista a [groups] csoportokkal; üres csoport nem jön.
  const ImportResultList({required this.groups, super.key});

  /// A csoportok a 13i sorrendjében.
  final List<ImportResultGroup> groups;

  /// A törzs legnagyobb magassága (13i).
  static const double maxHeight = 320;

  @override
  Widget build(BuildContext context) {
    final l10n = WebLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: maxHeight),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 10),
          children: [
            for (final group in groups) ...[
              RaceLogMonthHeader(
                monthLabel: _groupLabel(l10n, group.kind),
                countLabel: '${group.entries.length}',
              ),
              for (final entry in group.entries)
                _ResultRow(
                  entry: entry,
                  isSkipped: group.kind == ImportResultKind.skipped,
                ),
            ],
          ],
        ),
      ),
    );
  }

  static String _groupLabel(WebLocalizations l10n, ImportResultKind kind) =>
      switch (kind) {
        ImportResultKind.added => l10n.importGroupAdded,
        ImportResultKind.updated => l10n.importGroupUpdated,
        ImportResultKind.skipped => l10n.importGroupSkipped,
      };
}

/// Egy verseny sora: nap, név, jobbra a rövid dátum (13i).
class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.entry, required this.isSkipped});

  final ImportResultEntry entry;
  final bool isSkipped;

  // A kimaradt verseny napja helyén álló jel (13i): dátuma nincs.
  static const String _missingDay = '––';

  @override
  Widget build(BuildContext context) {
    final l10n = WebLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final tones = Theme.of(context).extension<TextTones>()!;
    final finishedAt = entry.finishedAt?.toLocal();

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SizedBox(
        height: 40,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              SizedBox(
                width: 22,
                child: Text(
                  finishedAt == null
                      ? _missingDay
                      : '${finishedAt.day}'.padLeft(2, '0'),
                  style: numeralMicroStyle.copyWith(color: tones.low),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  entry.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: supportTextStyle.copyWith(
                    fontSize: 14,
                    color: isSkipped
                        ? scheme.onSurfaceVariant
                        : scheme.onSurface,
                  ),
                ),
              ),
              if (finishedAt != null) ...[
                const SizedBox(width: 12),
                Text(
                  l10n.importRaceDate(finishedAt).toUpperCase(),
                  style: numeralCaptionStyle.copyWith(color: tones.low),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
