import 'dart:async';

import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:phone/app/foretack_typography.dart';
import 'package:phone/app/text_tones.dart';
import 'package:phone/app/theme.dart';
import 'package:phone/features/race_setup/widgets/form_action_bar.dart';
import 'package:phone/features/race_setup/widgets/form_bar_action.dart';
import 'package:phone/features/race_setup/widgets/mark_row.dart';
import 'package:phone/features/race_setup/widgets/saved_mark_picker.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:phone/widgets/foretack_switch.dart';
import 'package:phone/widgets/section_label.dart';
import 'package:shared/shared.dart';

/// Verseny-űrlap: név + dinamikus, átrendezhető bója-sorok.
///
/// A létrehozás (`RaceSetupScreen`) és a szerkesztés (`RaceEditScreen`)
/// közös magja (ADR 0029 D2). Befelé egy opcionális [initialRace] tölti
/// fel a mezőket: `null` = create (üres űrlap egy bója-sorral), nem-null =
/// edit (a meglévő név + bóják feltöltve). Kifelé egy MÁR VALIDÁLT
/// `(név, bóják)` párt ad az [onSubmit] callbacken — az id-forrást és a
/// mentés utáni navigációt a befoglaló képernyő intézi, így a form maga
/// nem ismeri a perzisztenciát.
///
/// A bója-sorok `ReorderableListView`-ben ülnek; a húzást explicit
/// drag-handle indítja (a sorokban `TextField`-ek vannak, a sor-szintű
/// long-press ütközne velük). A `Mark.sequence` nincs külön tárolva: a
/// submit a vizuális sorrend `index + 1`-éből gyártja, ezért a reorder a
/// domain/data réteget egyáltalán nem érinti.
///
/// **Elrendezés (ADR 0044 D1).** Görgetett törzs + rögzített akció-sáv: a
/// „Mentés" hat bójánál is elérhető marad görgetés nélkül. A sáv a formon
/// belül ül, ezért a két befoglaló képernyő nem tud róla — és nem is kell.
/// A sor-megjelenítés a [MarkRow]-ban van, itt csak az állapot marad.
///
/// **Bója nélküli verseny (ADR 0046 D4, Addendum 1 D7).** A verseny-név
/// alatti fix kapcsoló-sor kiveszi a bója-blokkot a fából, és a submit
/// üres listát ad ki. A koordináta-validáció ilyenkor magától kimarad,
/// mert a `Form.validate()` csak a fában lévő mezőket futtatja — nincs
/// feltételes validációs ág. A sor-állapot NEM törlődik, hogy a
/// vissza-kapcsolás a beírt adatokat visszaadja.
class RaceForm extends StatefulWidget {
  /// [initialRace] null = create (üres űrlap); nem-null = edit.
  const RaceForm({required this.onSubmit, this.initialRace, super.key});

  /// A feltöltés forrása, vagy null üres (create) űrlaphoz.
  final Race? initialRace;

  /// Validált submit: a vizuális sorrendből gyártott bójákkal hívódik.
  final void Function(String name, List<Mark> marks) onSubmit;

  @override
  State<RaceForm> createState() => _RaceFormState();
}

class _RaceFormState extends State<RaceForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final List<_MarkRowControllers> _markRows;

  /// Bója nélküli mód (ADR 0046 D4). Csak a megjelenítést és a submit
  /// kimenetét kapcsolja — a `_markRows` érintetlen marad alatta.
  late bool _isMarkless;

  @override
  void initState() {
    super.initState();
    final race = widget.initialRace;
    _nameController = TextEditingController(text: race?.name ?? '');
    // Edit: a meglévő bóják feltöltve; create: egy üres sorral indulunk (a
    // Race ctor a nemüres marks-ot asserteli, és az utolsót nem töröljük).
    _markRows = race == null || race.marks.isEmpty
        ? [_MarkRowControllers()]
        : [
            for (final mark in race.marks) _MarkRowControllers.fromMark(mark),
          ];
    // Edit-módban a tényleges állapot dönt; create-nél mindig kikapcsolva
    // indulunk, hogy a megszokott űrlap változatlan legyen.
    _isMarkless = race != null && race.marks.isEmpty;
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final row in _markRows) {
      row.dispose();
    }
    super.dispose();
  }

  void _addMarkRow() {
    setState(() => _markRows.add(_MarkRowControllers()));
  }

  Future<void> _pickFromLibrary() async {
    final picked = await showModalBottomSheet<SavedMark>(
      context: context,
      builder: (_) => const SavedMarkPicker(),
    );
    if (!mounted || picked == null) return;
    _addPickedMarkRow(picked);
  }

  void _addPickedMarkRow(SavedMark mark) {
    setState(
      () => _markRows.add(_MarkRowControllers.fromSavedMark(mark)),
    );
  }

  void _removeMarkRow(int index) {
    setState(() => _markRows.removeAt(index).dispose());
  }

  void _reorderMarkRow(int oldIndex, int newIndex) {
    setState(() {
      // A ReorderableListView a cél-indexet a törlés ELŐTTI listára adja;
      // lefelé húzáskor eggyel korrigálni kell.
      final target = newIndex > oldIndex ? newIndex - 1 : newIndex;
      _markRows.insert(target, _markRows.removeAt(oldIndex));
    });
  }

  // Egynél több sornál törölhető a sor; az utolsót megtartjuk (a Race
  // nemüres marks-ot vár). A closure a build-kori indexet zárja be — minden
  // setState új closure-öket gyárt a friss sorrenddel.
  VoidCallback? _onRemoveFor(int index) =>
      _markRows.length > 1 ? () => _removeMarkRow(index) : null;

  void _submit() {
    // A Form a fában van, így a currentState garantáltan nem null.
    if (!_formKey.currentState!.validate()) return;

    // Bója nélkül a sorok kikerültek a fából, tehát a validátoraik sem
    // futottak; a bennük maradt szöveget szándékosan eldobjuk (ADR 0046 D4).
    if (_isMarkless) {
      widget.onSubmit(_nameController.text.trim(), const []);
      return;
    }

    final marks = <Mark>[
      for (var i = 0; i < _markRows.length; i++)
        Mark(
          sequence: i + 1,
          name: _markRows[i].nameController.text.trim(),
          // A validáció után a lat/lon garantáltan érvényes tartomány.
          position: Coordinate.checked(
            latitude: _degrees(
              _markRows[i].latitudeController.text,
              GeoAxis.latitude,
            ),
            longitude: _degrees(
              _markRows[i].longitudeController.text,
              GeoAxis.longitude,
            ),
          ),
        ),
    ];

    widget.onSubmit(_nameController.text.trim(), marks);
  }

  String? _validateName(AppLocalizations l10n, String? value) =>
      (value == null || value.trim().isEmpty)
      ? l10n.setupMarkNameRequired
      : null;

  /// A `ParseGeoAngle` hibáját a megfelelő ARB-szövegre képezi (a tengely-
  /// tudatos OutOfRange-üzenettel), vagy null-t ad érvényes bemenetre.
  String? _coordinateError(AppLocalizations l10n, String? value, GeoAxis axis) {
    final result = const ParseGeoAngle().call(input: value ?? '', axis: axis);
    return switch (result) {
      Ok() => null,
      Err(error: EmptyInput()) => l10n.setupInvalidNumber,
      Err(error: Unrecognized()) => l10n.setupCoordinateUnrecognized,
      Err(error: ComponentOutOfRange()) => l10n.setupCoordinateComponentRange,
      Err(error: CardinalMismatch()) => l10n.setupCoordinateCardinalMismatch,
      Err(error: OutOfRange()) =>
        axis == GeoAxis.latitude
            ? l10n.setupLatitudeOutOfRange
            : l10n.setupLongitudeOutOfRange,
    };
  }

  /// A kártyán belüli mezők dekorációja (ADR 0044 D3).
  ///
  /// A téma alapját a kitöltés szűkíti: a mező `surfaceContainer`,
  /// mert a bója-sor háttere `surface`, és azonos színnel a mező
  /// eltűnne. Ez a korábbi elrendezés inverze (ADR 0044 D45). A
  /// radius a token-rétegben nullázódott (ADR 0044 D47).
  InputDecoration _rowFieldDecoration(String label) {
    final scheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      isDense: true,
      fillColor: scheme.surfaceContainer,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: foretackFieldBorder(scheme.outline),
      enabledBorder: foretackFieldBorder(scheme.outline),
      focusedBorder: foretackFieldBorder(scheme.primary, width: 1.5),
      errorBorder: foretackFieldBorder(scheme.error, width: 1.5),
      focusedErrorBorder: foretackFieldBorder(scheme.error, width: 1.5),
    );
  }

  Widget _coordinateField(
    AppLocalizations l10n,
    TextEditingController controller,
    GeoAxis axis,
  ) {
    return TextFormField(
      controller: controller,
      decoration: _rowFieldDecoration(
        axis == GeoAxis.latitude
            ? l10n.setupLatitudeLabel
            : l10n.setupLongitudeLabel,
      ),
      style: coordinateValueStyle,
      keyboardType: const TextInputType.numberWithOptions(
        signed: true,
        decimal: true,
      ),
      validator: (value) => _coordinateError(l10n, value, axis),
    );
  }

  Widget _markRow(AppLocalizations l10n, int index) {
    final row = _markRows[index];
    return MarkRow(
      // A reorder a KÖZVETLEN gyerekeket mozgatja, ezért a
      // sor-kulcs ide került, a korábbi Paddingről.
      key: ObjectKey(row),
      number: index + 1,
      // Explicit drag-handle: a sor-szintű long-press ütközne a
      // szövegmezőkkel, ezért csak innen indul a húzás.
      dragHandle: ReorderableDragStartListener(
        index: index,
        child: Tooltip(
          message: l10n.setupReorderHandle,
          child: const Icon(Icons.drag_indicator, size: 20),
        ),
      ),
      nameField: TextFormField(
        controller: row.nameController,
        decoration: _rowFieldDecoration(l10n.setupMarkNameLabel),
        textInputAction: TextInputAction.next,
        validator: (value) => _validateName(l10n, value),
      ),
      latitudeField: _coordinateField(
        l10n,
        row.latitudeController,
        GeoAxis.latitude,
      ),
      longitudeField: _coordinateField(
        l10n,
        row.longitudeController,
        GeoAxis.longitude,
      ),
      removeTooltip: l10n.setupRemoveMark,
      onRemove: _onRemoveFor(index),
    );
  }

  /// A bója nélküli mód kapcsoló-sora (ADR 0046 Addendum 1 D7).
  ///
  /// Fix helyen ül, a verseny-név alatt és a bója-blokk fölött: a bója
  /// nélküliség a VERSENYRE vonatkozó tulajdonság, nem a bója-listára,
  /// ezért a névvel egy szinten áll. Bekapcsolva a blokk eltűnik alatta,
  /// a sor maga nem mozdul.
  ///
  /// A magyarázó sor **kikapcsolva is látszik**: a következmény (nincs
  /// bearing, ETA és predikció) különben a vízen derülne ki.
  Widget _marklessRow(AppLocalizations l10n) {
    final theme = Theme.of(context);
    // A foretackTheme regisztrálja a TextTones-t → a fában mindig jelen van.
    final tones = theme.extension<TextTones>()!;
    final line = BorderSide(color: theme.colorScheme.outlineVariant);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: line, bottom: line),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.setupNoMarksToggle,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.setupNoMarksHint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: tones.low,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            ForetackSwitch(
              value: _isMarkless,
              onChanged: (value) => setState(() => _isMarkless = value),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Form(
      key: _formKey,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              // Teljes szélességű törzs: a bója-sorok és a kapcsoló-sor
              // hairline-jai a képernyő széléig futnak (ADR 0044 D45).
              padding: const EdgeInsets.only(top: 8),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
                  child: TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: l10n.setupRaceNameLabel,
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? l10n.setupRaceNameRequired
                        : null,
                  ),
                ),
                _marklessRow(l10n),
                if (!_isMarkless) ...[
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SectionLabel(text: l10n.setupMarksSection),
                  ),
                  const SizedBox(height: 6),
                  // A bója-sorok átrendezhetők; a ReorderableListView a
                  // külső ListView-on belül zsugorodik és nem görget külön.
                  // A sorokat hairline választja el (ADR 0044 D45), ezért
                  // köztük nincs rés, és a sor-kulcs a MarkRow-n ül.
                  ReorderableListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    buildDefaultDragHandles: false,
                    onReorder: _reorderMarkRow,
                    children: [
                      for (var i = 0; i < _markRows.length; i++)
                        _markRow(l10n, i),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Bója nélküli módban nincs mit hozzáadni: a lista üres,
          // és a sáv egyetlen, teljes szélességű Mentés gombra esik
          // (ADR 0046 D4).
          FormActionBar(
            primaryLabel: l10n.setupSave,
            onPrimary: _submit,
            secondaryActions: _isMarkless
                ? const []
                : [
                    FormBarAction(
                      label: l10n.setupAddMark,
                      icon: Icons.add,
                      onTap: _addMarkRow,
                    ),
                    FormBarAction(
                      label: l10n.setupPickFromLibrary,
                      icon: Icons.history,
                      onTap: () => unawaited(_pickFromLibrary()),
                    ),
                  ],
          ),
        ],
      ),
    );
  }
}

/// Egy bója-sor szerkeszthető mezőinek kontroller-csoportja.
class _MarkRowControllers {
  _MarkRowControllers({
    String name = '',
    String latitude = '',
    String longitude = '',
  }) : nameController = TextEditingController(text: name),
       latitudeController = TextEditingController(text: latitude),
       longitudeController = TextEditingController(text: longitude);

  /// Egy meglévő bójából tölti fel a sort (edit-mód feltöltése).
  factory _MarkRowControllers.fromMark(Mark mark) => _MarkRowControllers(
    name: mark.name,
    latitude: mark.position.latitude.toString(),
    longitude: mark.position.longitude.toString(),
  );

  /// Egy könyvtárbeli bójából tölti fel a sort (picker-választás).
  factory _MarkRowControllers.fromSavedMark(SavedMark mark) {
    return _MarkRowControllers(
      name: mark.name,
      latitude: mark.position.latitude.toString(),
      longitude: mark.position.longitude.toString(),
    );
  }

  final TextEditingController nameController;
  final TextEditingController latitudeController;
  final TextEditingController longitudeController;

  void dispose() {
    nameController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
  }
}

/// A validáció utáni biztos koordináta-parse: a `ParseGeoAngle` itt már
/// garantáltan Ok-ot ad (a form validált), így az Err-ág programozói hiba.
double _degrees(String text, GeoAxis axis) {
  return switch (const ParseGeoAngle().call(input: text, axis: axis)) {
    Ok(value: final value) => value,
    Err(error: final error) => throw StateError(
      'Coordinate parse failed after validation: $error',
    ),
  };
}
