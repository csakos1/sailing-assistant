import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:foretack_web/app/web_layout.dart';
import 'package:foretack_web/race_log/table/cells/table_cell_padding.dart';
import 'package:foretack_web/race_log/table/cells/table_cell_styles.dart';
import 'package:foretack_web/race_log/table/race_table_row.dart';
import 'package:race_archive_api/race_archive_api.dart';

/// Egy helyezés a saját mezőnyével (G2): jobbra zárt szám, perjeles,
/// tompított mezőny; a perjelek egy oszlopba esnek. DNF és DSQ mellett a
/// mezőny nem látszik; az 1–3. hely alatt talapzat (G6).
class TablePlacingCell extends StatelessWidget {
  /// Cella a [placing] helyezéssel.
  const TablePlacingCell({required this.placing, super.key});

  /// A helyezés és a mezőny.
  final TablePlacing placing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // A `!` biztonságos: a `foretackTheme` regisztrálja a `TextTones`-t.
    final tones = Theme.of(context).extension<TextTones>()!;
    final fleetSize = placing.fleetSize;
    final (text, isNumber, isPodium) = switch (placing.placing) {
      FinishPlace(:final place) => ('$place', true, place <= 3),
      Dnf() => ('DNF', false, false),
      Dsq() => ('DSQ', false, false),
    };
    final placeText = Text(
      text,
      maxLines: 1,
      softWrap: false,
      style: tableNumberStyle.copyWith(
        color: isNumber ? scheme.onSurface : scheme.onSurfaceVariant,
      ),
    );

    return TableCellPadding(
      child: Row(
        children: [
          SizedBox(
            width: WebLayout.tablePlaceWidth,
            child: Align(
              alignment: Alignment.centerRight,
              child: isPodium
                  ? DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: scheme.onSurfaceVariant,
                            width: WebLayout.tablePodiumThickness,
                          ),
                        ),
                      ),
                      child: placeText,
                    )
                  : placeText,
            ),
          ),
          SizedBox(
            width: WebLayout.tableFleetWidth,
            child: isNumber && fleetSize != null
                ? Text(
                    '/$fleetSize',
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.clip,
                    style: tableNumberStyle.copyWith(color: tones.low),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
