import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:foretack_web/app/web_layout.dart';
import 'package:foretack_web/l10n/web_localizations.dart';
import 'package:foretack_web/race_edit/form/form_text_parsers.dart';
import 'package:foretack_web/race_edit/form/local_instant.dart';

/// A telemetriás szerkesztő csak olvasható kontextus-sávja (ADR 0048
/// Addendum 1 G4, makett 13m, 14p): a verseny neve, a napja és a
/// rögzítés ideje, jobbra „A TELEFON ADATA · NEM SZERKESZTHETŐ".
class TelemetryEditorHeader extends StatelessWidget {
  /// Sáv a [name] versenyhez a [recording] rögzítési ablakkal.
  const TelemetryEditorHeader({
    required this.name,
    required this.recording,
    super.key,
  });

  /// A verseny neve.
  final String name;

  /// A rögzítés kezdete és vége (UTC).
  final TimeWindow recording;

  @override
  Widget build(BuildContext context) {
    final l10n = WebLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final tones = Theme.of(context).extension<TextTones>()!;
    final recordingLine = l10n.editRecordingCaps(
      formatFormDate(localDateOf(recording.start)),
      _clock(recording.start),
      _clock(recording.end),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(WebLayout.columnInset),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: supportTextStyle.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    recordingLine,
                    style: statusLabelStyle.copyWith(color: tones.low),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                l10n.editTelemetryReadOnlyCaps,
                style: statusLabelStyle.copyWith(
                  fontSize: 9,
                  color: tones.low,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // A rögzítés ideje másodpercre, mint a phone műszer-sorában.
  static String _clock(DateTime instant) {
    final time = localClockOf(instant);
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(time.hour)}:${two(time.minute)}:${two(time.second)}';
  }
}
