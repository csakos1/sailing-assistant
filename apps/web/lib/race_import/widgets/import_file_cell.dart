import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:foretack_web/l10n/web_localizations.dart';
import 'package:foretack_web/race_import/file_size_format.dart';
import 'package:foretack_web/race_import/picked_file.dart';

/// A feltöltés fájl-cellája (ADR 0047 E6, ADR 0048 Addendum 4 K22,
/// makett 13f–13h).
///
/// A szerkesztő mezőinek nyelvén: keret a tetején verzál felirattal,
/// benne a fájl neve és mérete, jobbra a TALLÓZÁS vagy CSERE. Az egész
/// cella kattintható, és Enterrel is nyílik. Feltöltés közben tiltott és
/// halvány (13h).
class ImportFileCell extends StatefulWidget {
  /// Cella a [label] felirattal és a választott [file]-lal; az
  /// [onPressed] `null`-nál tiltott.
  const ImportFileCell({
    required this.label,
    required this.file,
    required this.onPressed,
    this.sizeText,
    this.autofocus = false,
    super.key,
  });

  /// A keret tetején álló verzál felirat.
  final String label;

  /// A választott fájl; `null`-nál a „Nincs kiválasztva" szöveg áll.
  final PickedFile? file;

  /// A választás megnyitása; `null`-nál a cella tiltott.
  final VoidCallback? onPressed;

  /// A méret helyén álló szöveg (feltöltés közben `3,2 / 4,8 MB`);
  /// alapból a fájl mérete.
  final String? sizeText;

  /// Megnyitáskor fókuszt kap-e.
  final bool autofocus;

  /// A tiltott cella átlátszósága a makett 13h-ja szerint.
  static const double disabledOpacity = 0.45;

  @override
  State<ImportFileCell> createState() => _ImportFileCellState();
}

class _ImportFileCellState extends State<ImportFileCell> {
  bool _isHovering = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final l10n = WebLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final tones = Theme.of(context).extension<TextTones>()!;
    final file = widget.file;
    final labelStyle = statusLabelStyle.copyWith(
      fontSize: 9,
      color: scheme.onSurfaceVariant,
    );

    return Opacity(
      opacity: widget.onPressed == null ? ImportFileCell.disabledOpacity : 1,
      child: InkWell(
        onTap: widget.onPressed,
        autofocus: widget.autofocus,
        onHover: (isHovering) => setState(() => _isHovering = isHovering),
        onFocusChange: (isFocused) => setState(() => _isFocused = isFocused),
        // A visszajelzést a mező kerete és kitöltése adja, nem az InkWell
        // rétege, amelyet a kitöltés úgyis eltakarna.
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
        child: InputDecorator(
          isFocused: _isFocused,
          isHovering: _isHovering,
          decoration: InputDecoration(
            labelText: widget.label,
            floatingLabelBehavior: FloatingLabelBehavior.always,
            labelStyle: labelStyle,
            floatingLabelStyle: labelStyle,
            fillColor: scheme.surface,
            hoverColor: scheme.surfaceContainerHigh,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 17,
            ),
            suffixIcon: _CellAction(
              label: file == null
                  ? l10n.importBrowseCaps
                  : l10n.importReplaceCaps,
            ),
            suffixIconConstraints: const BoxConstraints(minHeight: 50),
          ),
          child: file == null
              ? Text(
                  l10n.importNoFile,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: supportTextStyle.copyWith(
                    fontSize: 14,
                    color: tones.low,
                  ),
                )
              : Row(
                  children: [
                    Flexible(
                      child: Text(
                        file.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: coordinateValueStyle.copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      widget.sizeText ?? formatFileSize(file.sizeBytes),
                      style: numeralCaptionStyle.copyWith(color: tones.low),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// A cella jobb oldali akció-felirata, elválasztó vonallal (13f).
class _CellAction extends StatelessWidget {
  const _CellAction({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: scheme.outline)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Center(
          widthFactor: 1,
          child: Text(
            label,
            style: statusLabelStyle.copyWith(color: scheme.onSurface),
          ),
        ),
      ),
    );
  }
}
