import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:foretack_web/app/web_layout.dart';

/// A szerkesztő egysoros mezője: 54 px magas doboz, a keret tetején verzál
/// felirattal (ADR 0048 Addendum 1 G4, makett 14r).
///
/// A [normalize] kilépéskor (fókuszvesztéskor) fut: egy olvasható szöveget
/// az egységes alakra ír át (pl. `1000` → `10:00`), az olvashatatlant
/// `null`-lal érintetlenül hagyja, hogy a hiba látsszon.
class BoxedTextField extends StatefulWidget {
  /// Mező a [controller] szövegével és a [label] felirattal.
  const BoxedTextField({
    required this.controller,
    required this.label,
    this.focusNode,
    this.hint,
    this.width,
    this.valueStyle = _defaultValueStyle,
    this.isCentered = true,
    this.isEnabled = true,
    this.hasProblem = false,
    this.autofocus = false,
    this.keyboardType,
    this.normalize,
    super.key,
  });

  /// A mező szövege.
  final TextEditingController controller;

  /// A mező fókusza; a hibás mezőre a szerkesztő ugrik vele.
  final FocusNode? focusNode;

  /// A keret tetején álló verzál felirat.
  final String label;

  /// Kitöltési minta üres mezőben.
  final String? hint;

  /// Rögzített szélesség; `null`-nál kitölti a sort.
  final double? width;

  /// Az érték stílusa (szám-mezőn a Martian Mono fokozat).
  final TextStyle valueStyle;

  /// Középre zárt-e a szöveg (a szám-mezők igen, a név nem).
  final bool isCentered;

  /// Szerkeszthető-e (DNF/DSQ mellett a helyezés-mező nem).
  final bool isEnabled;

  /// Hibás-e: piros keret és felirat (13n).
  final bool hasProblem;

  /// Megnyitáskor fókuszt kap-e (az új verseny neve, G5).
  final bool autofocus;

  /// A billentyűzet fajtája.
  final TextInputType? keyboardType;

  /// Kilépéskor futó egységesítés; `null` eredmény = marad a szöveg.
  final String? Function(String text)? normalize;

  static const TextStyle _defaultValueStyle = TextStyle(
    fontFamily: uiFontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w600,
  );

  @override
  State<BoxedTextField> createState() => _BoxedTextFieldState();
}

class _BoxedTextFieldState extends State<BoxedTextField> {
  FocusNode? _ownFocusNode;

  FocusNode get _focusNode =>
      widget.focusNode ?? (_ownFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(BoxedTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldNode = oldWidget.focusNode ?? _ownFocusNode;
    if (oldNode != _focusNode) {
      oldNode?.removeListener(_onFocusChanged);
      _focusNode.addListener(_onFocusChanged);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _ownFocusNode?.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    final normalize = widget.normalize;
    if (_focusNode.hasFocus || normalize == null) return;
    final normalized = normalize(widget.controller.text);
    if (normalized != null && normalized != widget.controller.text) {
      widget.controller.text = normalized;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tones = Theme.of(context).extension<TextTones>()!;
    final labelColor = widget.hasProblem
        ? scheme.error
        : scheme.onSurfaceVariant;
    final problemBorder = foretackFieldBorder(scheme.error, width: 1.5);

    final field = TextField(
      controller: widget.controller,
      focusNode: _focusNode,
      enabled: widget.isEnabled,
      autofocus: widget.autofocus,
      keyboardType: widget.keyboardType,
      textAlign: widget.isCentered ? TextAlign.center : TextAlign.start,
      style: widget.valueStyle.copyWith(
        color: widget.isEnabled ? scheme.onSurface : tones.low,
      ),
      decoration: InputDecoration(
        labelText: widget.label,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelStyle: statusLabelStyle.copyWith(fontSize: 9, color: labelColor),
        floatingLabelStyle: statusLabelStyle.copyWith(
          fontSize: 9,
          color: labelColor,
        ),
        hintText: widget.hint,
        hintStyle: supportTextStyle.copyWith(color: tones.low),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        constraints: const BoxConstraints(
          minHeight: WebLayout.editorFieldHeight,
        ),
        enabledBorder: widget.hasProblem ? problemBorder : null,
        focusedBorder: widget.hasProblem ? problemBorder : null,
      ),
    );

    final width = widget.width;
    return width == null ? field : SizedBox(width: width, child: field);
  }
}
