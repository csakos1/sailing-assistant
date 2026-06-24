import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:phone/l10n/app_localizations.dart';
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(labelText: l10n.setupRaceNameLabel),
            textInputAction: TextInputAction.next,
            validator: (value) => (value == null || value.trim().isEmpty)
                ? l10n.setupRaceNameRequired
                : null,
          ),
          // A bója-sorok átrendezhetők; a ReorderableListView a külső
          // ListView-on belül zsugorodik és nem görget külön.
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            onReorder: _reorderMarkRow,
            children: [
              for (var i = 0; i < _markRows.length; i++)
                _MarkRowFields(
                  key: ObjectKey(_markRows[i]),
                  index: i,
                  l10n: l10n,
                  controllers: _markRows[i],
                  number: i + 1,
                  onRemove: _onRemoveFor(i),
                ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _addMarkRow,
            icon: const Icon(Icons.add),
            label: Text(l10n.setupAddMark),
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: _submit, child: Text(l10n.setupSave)),
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

  final TextEditingController nameController;
  final TextEditingController latitudeController;
  final TextEditingController longitudeController;

  void dispose() {
    nameController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
  }
}

/// Egy bója-sor megjelenítése: drag-handle + sorszám-fejléc, név/lat/lon
/// mezők, és (egynél több sornál) törlés gomb.
class _MarkRowFields extends StatelessWidget {
  const _MarkRowFields({
    required this.index,
    required this.l10n,
    required this.controllers,
    required this.number,
    required this.onRemove,
    super.key,
  });

  final int index;
  final AppLocalizations l10n;
  final _MarkRowControllers controllers;
  final int number;
  final VoidCallback? onRemove;

  String? _validateName(String? value) =>
      (value == null || value.trim().isEmpty)
      ? l10n.setupMarkNameRequired
      : null;

  String? _validateLatitude(String? value) =>
      _coordinateError(value, GeoAxis.latitude);

  String? _validateLongitude(String? value) =>
      _coordinateError(value, GeoAxis.longitude);

  /// A `ParseGeoAngle` hibáját a megfelelő ARB-szövegre képezi (a tengely-
  /// tudatos OutOfRange-üzenettel), vagy null-t ad érvényes bemenetre.
  String? _coordinateError(String? value, GeoAxis axis) {
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Explicit drag-handle: a sor-szintű long-press ütközne a
              // szövegmezőkkel, ezért csak innen indul a húzás.
              ReorderableDragStartListener(
                index: index,
                child: Tooltip(
                  message: l10n.setupReorderHandle,
                  child: const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(Icons.drag_handle),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  l10n.setupMarkHeader(number),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              if (onRemove != null)
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.remove_circle_outline),
                  tooltip: l10n.setupRemoveMark,
                ),
            ],
          ),
          TextFormField(
            controller: controllers.nameController,
            decoration: InputDecoration(labelText: l10n.setupMarkNameLabel),
            textInputAction: TextInputAction.next,
            validator: _validateName,
          ),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controllers.latitudeController,
                  decoration: InputDecoration(
                    labelText: l10n.setupLatitudeLabel,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: true,
                    decimal: true,
                  ),
                  validator: _validateLatitude,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: controllers.longitudeController,
                  decoration: InputDecoration(
                    labelText: l10n.setupLongitudeLabel,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: true,
                    decimal: true,
                  ),
                  validator: _validateLongitude,
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
