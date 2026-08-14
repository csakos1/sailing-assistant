import 'dart:async';

import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:phone/app/text_tones.dart';
import 'package:phone/app/theme.dart';
import 'package:phone/features/race_setup/widgets/form_action_bar.dart';
import 'package:phone/features/race_setup/widgets/mark_row_card.dart';
import 'package:phone/features/race_setup/widgets/saved_mark_picker.dart';
import 'package:phone/l10n/app_localizations.dart';
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
/// A sor-megjelenítés a [MarkRowCard]-ban van, itt csak az állapot marad.
///
/// **Bója nélküli verseny (ADR 0046 D4).** A „BÓJÁK" fejléc-sor jobb
/// szélén álló kapcsoló kiveszi a bója-blokkot a fából, és a submit
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
  /// A téma alapját a kitöltés szűkíti: `surface`, mert a kártya
  /// háttere már `surfaceContainer` — azonos színnel a mező eltűnne —, és a
  /// radius a token-rétegben nullázódott (ADR 0044 D47).
  InputDecoration _cardFieldDecoration(String label) {
    final scheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      isDense: true,
      fillColor: scheme.surface,
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
      decoration: _cardFieldDecoration(
        axis == GeoAxis.latitude
            ? l10n.setupLatitudeLabel
            : l10n.setupLongitudeLabel,
      ),
      keyboardType: const TextInputType.numberWithOptions(
        signed: true,
        decimal: true,
      ),
      validator: (value) => _coordinateError(l10n, value, axis),
    );
  }

  Widget _markRowCard(AppLocalizations l10n, int index) {
    final row = _markRows[index];
    return MarkRowCard(
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
        decoration: _cardFieldDecoration(l10n.setupMarkNameLabel),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // A foretackTheme regisztrálja a TextTones-t → a fában mindig jelen van.
    final tones = Theme.of(context).extension<TextTones>()!;

    return Form(
      key: _formKey,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: l10n.setupRaceNameLabel,
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? l10n.setupRaceNameRequired
                      : null,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: SectionLabel(text: l10n.setupMarksSection),
                    ),
                    // Halk, tonális kapcsoló a fejléc-sor jobb szélén: nem
                    // kér plusz függőleges helyet (ADR 0046 D4).
                    FilterChip(
                      label: Text(l10n.setupNoMarksToggle),
                      selected: _isMarkless,
                      onSelected: (value) =>
                          setState(() => _isMarkless = value),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (_isMarkless)
                  // Üres szakasz felirat nélkül hibásnak látszik, a
                  // következmény pedig egyébként a vízen derülne ki.
                  Text(
                    l10n.setupNoMarksHint,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: tones.low),
                  )
                else ...[
                  // A bója-sorok átrendezhetők; a ReorderableListView a
                  // külső ListView-on belül zsugorodik és nem görget külön.
                  // A sor-kulcs a Paddingen ül, mert a reorder a KÖZVETLEN
                  // gyerekeket mozgatja.
                  ReorderableListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    buildDefaultDragHandles: false,
                    onReorder: _reorderMarkRow,
                    children: [
                      for (var i = 0; i < _markRows.length; i++)
                        Padding(
                          key: ObjectKey(_markRows[i]),
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _markRowCard(l10n, i),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.tonalIcon(
                      onPressed: () => unawaited(_pickFromLibrary()),
                      icon: const Icon(Icons.history, size: 17),
                      label: Text(l10n.setupPickFromLibrary),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(14)),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Bója nélküli módban nincs mit hozzáadni: a sáv egyetlen,
          // teljes szélességű Mentés gombra esik (ADR 0046 D4).
          FormActionBar(
            primaryLabel: l10n.setupSave,
            onPrimary: _submit,
            secondaryLabel: _isMarkless ? null : l10n.setupAddMark,
            secondaryIcon: _isMarkless ? null : Icons.add,
            onSecondary: _isMarkless ? null : _addMarkRow,
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
