import 'dart:async';

import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/features/race_setup/race_form_result.dart';
import 'package:phone/features/race_setup/start_time/start_time_calendar.dart';
import 'package:phone/features/race_setup/start_time/start_time_sheet.dart';
import 'package:phone/features/race_setup/widgets/card_field_decoration.dart';
import 'package:phone/features/race_setup/widgets/coordinate_card.dart';
import 'package:phone/features/race_setup/widgets/form_action_bar.dart';
import 'package:phone/features/race_setup/widgets/form_bar_action.dart';
import 'package:phone/features/race_setup/widgets/form_card.dart';
import 'package:phone/features/race_setup/widgets/form_section_header.dart';
import 'package:phone/features/race_setup/widgets/saved_mark_picker.dart';
import 'package:phone/features/race_setup/widgets/start_point_empty_card.dart';
import 'package:phone/features/race_setup/widgets/start_time_card.dart';
import 'package:phone/format/scheduled_start_format.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:phone/widgets/foretack_switch.dart';
import 'package:shared/shared.dart';

/// A kártyák oldalsó margója és a köztük lévő köz (33a).
const double _sideMargin = 20;
const double _cardGap = 10;

/// A cellák magassága (33a): verseny-név, kártya-név, koordináta.
const double _raceNameHeight = 54;
const double _nameHeight = 48;
const double _coordinateHeight = 44;

/// Verseny-űrlap (33a–c): név, rajtidő, bója nélküli kapcsoló, rajthely
/// és átrendezhető bója-kártyák.
///
/// A létrehozás (`RaceSetupScreen`) és a szerkesztés (`RaceEditScreen`)
/// közös magja (ADR 0029 D2). Befelé egy opcionális [initialRace] tölti
/// fel a mezőket: `null` = create (üres űrlap egy bója-kártyával), nem-null
/// = edit (a meglévő név, rajtidő, rajthely és bóják). Kifelé egy MÁR
/// VALIDÁLT [RaceFormResult]-ot ad az [onSubmit]-en — az id-forrást és a
/// mentés utáni navigációt a befoglaló képernyő intézi.
///
/// A bója-kártyák `ReorderableListView`-ben ülnek; a húzást explicit
/// drag-handle indítja (a kártyákban `TextField`-ek vannak). A
/// `Mark.sequence` a submitkor a vizuális sorrend `index + 1`-éből jön.
///
/// **Rajtidő és rajthely (ADR 0055 D9, ADR 0056 U7).** A rajtidő egy UTC
/// pillanat az állapotban; a kártya és a választó (33c) helyi időben
/// mutatja. A rajthely opcionális, bója nélküli versenyen is megadható
/// (ADR 0055 D1); a mezői ugyanúgy validálódnak, mint a bójáéi.
///
/// **Bója nélküli verseny (ADR 0046 D4).** A kapcsoló kiveszi a bója-
/// blokkot a fából, és a submit üres listát ad ki. A koordináta-validáció
/// ilyenkor magától kimarad, mert a `Form.validate()` csak a fában lévő
/// mezőket futtatja. A sor-állapot NEM törlődik, hogy a vissza-kapcsolás a
/// beírt adatokat visszaadja.
class RaceForm extends StatefulWidget {
  /// [initialRace] null = create (üres űrlap); nem-null = edit.
  const RaceForm({
    required this.onSubmit,
    this.initialRace,
    this.now = DateTime.now,
    super.key,
  });

  /// A feltöltés forrása, vagy null üres (create) űrlaphoz.
  final Race? initialRace;

  /// Validált submit a teljes űrlap-eredménnyel.
  final void Function(RaceFormResult result) onSubmit;

  /// A „most" pillanat: a választó kezdőértékéhez és az elmúlt rajtidő
  /// jelzéséhez. A képernyők a `clockProvider`-t adják.
  final DateTime Function() now;

  @override
  State<RaceForm> createState() => _RaceFormState();
}

class _RaceFormState extends State<RaceForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final List<_PointControllers> _markRows;

  /// Bója nélküli mód (ADR 0046 D4). Csak a megjelenítést és a submit
  /// kimenetét kapcsolja — a `_markRows` érintetlen marad alatta.
  late bool _isMarkless;

  /// A tervezett rajt UTC pillanata, vagy `null` (ADR 0055 D1).
  DateTime? _scheduledStartAt;

  /// A rajthely mezői, vagy `null`, ha nincs rajthely.
  _PointControllers? _startPoint;

  @override
  void initState() {
    super.initState();
    final race = widget.initialRace;
    _nameController = TextEditingController(text: race?.name ?? '');
    // Edit: a meglévő bóják feltöltve; create: egy üres sorral indulunk
    // (az utolsót nem töröljük).
    _markRows = race == null || race.marks.isEmpty
        ? [_PointControllers()]
        : [
            for (final mark in race.marks)
              _PointControllers.fromPosition(mark.name, mark.position),
          ];
    _isMarkless = race != null && race.marks.isEmpty;
    _scheduledStartAt = race?.scheduledStartAt?.toUtc();
    final startPoint = race?.startPoint;
    if (startPoint != null) {
      _startPoint = _PointControllers.fromPosition(
        startPoint.name,
        startPoint.position,
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final row in _markRows) {
      row.dispose();
    }
    _startPoint?.dispose();
    super.dispose();
  }

  Future<SavedMark?> _openLibrary() {
    return showModalBottomSheet<SavedMark>(
      context: context,
      // A lap a képernyő felénél magasabb, ezért scroll-vezérelt módban
      // nyitjuk; a magasság-korlátot maga a picker adja (D51).
      isScrollControlled: true,
      showDragHandle: true,
      // A design-rendszer minden felülete r0 (ADR 0044 D47).
      shape: const RoundedRectangleBorder(),
      // A modal sheet magától NEM tér ki a billentyűzet elől, a
      // kereső-mező (D52) pedig különben alá csúszna.
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: const SavedMarkPicker(),
      ),
    );
  }

  void _addMarkRow() {
    setState(() => _markRows.add(_PointControllers()));
  }

  Future<void> _pickMarkFromLibrary() async {
    final picked = await _openLibrary();
    if (!mounted || picked == null) return;
    setState(
      () => _markRows.add(
        _PointControllers.fromPosition(picked.name, picked.position),
      ),
    );
  }

  void _removeMarkRow(int index) {
    final removed = _markRows[index];
    setState(() => _markRows.removeAt(index));
    WidgetsBinding.instance.addPostFrameCallback((_) => removed.dispose());
  }

  void _reorderMarkRow(int oldIndex, int newIndex) {
    setState(() {
      // A ReorderableListView a cél-indexet a törlés ELŐTTI listára adja;
      // lefelé húzáskor eggyel korrigálni kell.
      final target = newIndex > oldIndex ? newIndex - 1 : newIndex;
      _markRows.insert(target, _markRows.removeAt(oldIndex));
    });
  }

  // Egynél több sornál törölhető a sor; az utolsót megtartjuk. A closure a
  // build-kori indexet zárja be — minden setState új closure-öket gyárt.
  VoidCallback? _onRemoveFor(int index) =>
      _markRows.length > 1 ? () => _removeMarkRow(index) : null;

  Future<void> _openStartTime() async {
    final localNow = widget.now().toLocal();
    final choice = await showStartTimeSheet(
      context,
      initial: _scheduledStartAt?.toLocal() ?? defaultStartTime(localNow),
      today: localNow,
    );
    // A lap bezárása választás nélkül nem változtat semmit.
    if (!mounted || choice == null) return;
    setState(() => _scheduledStartAt = choice.localStart?.toUtc());
  }

  void _clearStartTime() => setState(() => _scheduledStartAt = null);

  Future<void> _pickStartPointFromLibrary() async {
    final picked = await _openLibrary();
    if (!mounted || picked == null) return;
    _replaceStartPoint(
      _PointControllers.fromPosition(picked.name, picked.position),
    );
  }

  void _enterStartPointCoordinates() {
    // Üres mezők, a fókusz a névre kerül: a „Koordináta" út a gépelésé.
    _replaceStartPoint(_PointControllers(shouldFocusName: true));
  }

  void _replaceStartPoint(_PointControllers? next) {
    final previous = _startPoint;
    setState(() => _startPoint = next);
    // A régi kontrollereket a következő frame után dobjuk el, amikor a
    // mezőik már biztosan lekerültek a fáról (a bója-sor törlése
    // ugyanezt teszi).
    if (previous != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => previous.dispose());
    }
  }

  void _submit() {
    // A Form a fában van, így a currentState garantáltan nem null.
    if (!_formKey.currentState!.validate()) return;

    widget.onSubmit((
      name: _nameController.text.trim(),
      // Bója nélkül a sorok kikerültek a fából, tehát a validátoraik sem
      // futottak; a bennük maradt szöveget szándékosan eldobjuk.
      marks: _isMarkless
          ? const <Mark>[]
          : [
              for (var i = 0; i < _markRows.length; i++)
                Mark(
                  sequence: i + 1,
                  name: _markRows[i].nameController.text.trim(),
                  position: _markRows[i].position(),
                ),
            ],
      scheduledStartAt: _scheduledStartAt,
      startPoint: _startPointValue(),
    ));
  }

  StartPoint? _startPointValue() {
    final startPoint = _startPoint;
    if (startPoint == null) return null;
    return StartPoint(
      name: startPoint.nameController.text.trim(),
      position: startPoint.position(),
    );
  }

  /// Az elmúlt rajtidő halk jelzése (felhasználói döntés, U7).
  ///
  /// A mentés nem tiltott (ADR 0055 D9). Az engine egy elmúlt rajtot csak
  /// a mai napon, a késési ablakon belül indít visszamenőleg (ADR 0055
  /// D5, D7); azon túl a verseny csak kézzel indul — a jelzés ezt mondja.
  String? _startTimeNote(AppLocalizations l10n) {
    final start = _scheduledStartAt;
    if (start == null) return null;
    final now = widget.now();
    if (!start.isBefore(now)) return null;
    final windowEnd = start.add(SelectInstrumentsRace.defaultLateStartWindow);
    final isRetroactive =
        now.isBefore(windowEnd) &&
        isSameLocalDay(start.toLocal(), now.toLocal());
    return isRetroactive
        ? l10n.setupStartTimePastRetroactive
        : l10n.setupStartTimePastManual;
  }

  String? _validateName(AppLocalizations l10n, String? value) =>
      (value == null || value.trim().isEmpty)
      ? l10n.setupMarkNameRequired
      : null;

  /// A `ParseGeoAngle` hibáját a megfelelő ARB-szövegre képezi, vagy null-t
  /// ad érvényes bemenetre. A bevitel DD-t, DDM-et és DMS-t is elfogad.
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

  Widget _nameField(
    AppLocalizations l10n,
    _PointControllers row, {
    required String hint,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final style = supportTextStyle.copyWith(
      fontSize: 15,
      height: cardFieldLineHeight,
      color: scheme.onSurface,
    );
    return TextFormField(
      controller: row.nameController,
      autofocus: row.shouldFocusName,
      decoration: cardFieldDecoration(
        context,
        hint: hint,
        style: style,
        height: _nameHeight,
      ),
      style: style,
      textInputAction: TextInputAction.next,
      validator: (value) => _validateName(l10n, value),
    );
  }

  Widget _coordinateField(
    AppLocalizations l10n,
    TextEditingController controller,
    GeoAxis axis,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final style = coordinateValueStyle.copyWith(
      fontSize: 13,
      height: cardFieldLineHeight,
      color: scheme.onSurfaceVariant,
    );
    return TextFormField(
      controller: controller,
      decoration: cardFieldDecoration(
        context,
        hint: axis == GeoAxis.latitude
            ? l10n.setupLatitudeLabel
            : l10n.setupLongitudeLabel,
        style: style,
        height: _coordinateHeight,
      ),
      style: style,
      keyboardType: const TextInputType.numberWithOptions(
        signed: true,
        decimal: true,
      ),
      validator: (value) => _coordinateError(l10n, value, axis),
    );
  }

  Widget _markCard(AppLocalizations l10n, int index) {
    // A foretackTheme regisztrálja a TextTones-t → a fában mindig jelen van.
    final tones = Theme.of(context).extension<TextTones>()!;
    final row = _markRows[index];
    final isLast = index == _markRows.length - 1;
    return Padding(
      // A reorder a KÖZVETLEN gyerekeket mozgatja, ezért a kulcs itt ül.
      key: ObjectKey(row),
      padding: EdgeInsets.only(bottom: isLast ? 0 : _cardGap),
      child: CoordinateCard(
        rail: Column(
          spacing: 8,
          children: [
            Text(
              '${index + 1}'.padLeft(2, '0'),
              style: numeralMicroStyle.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: tones.low,
              ),
            ),
            // Explicit drag-handle: a kártya-szintű long-press ütközne a
            // szövegmezőkkel, ezért csak innen indul a húzás.
            ReorderableDragStartListener(
              index: index,
              child: Tooltip(
                message: l10n.setupReorderHandle,
                child: Icon(Icons.drag_indicator, size: 20, color: tones.low),
              ),
            ),
          ],
        ),
        nameField: _nameField(l10n, row, hint: l10n.setupMarkNameLabel),
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
      ),
    );
  }

  Widget _startPointSection(AppLocalizations l10n) {
    final startPoint = _startPoint;
    if (startPoint == null) {
      return StartPointEmptyCard(
        title: l10n.setupStartPointAdd,
        libraryLabel: l10n.setupPickFromLibrary,
        coordinatesLabel: l10n.setupStartPointCoordinates,
        onPickFromLibrary: () => unawaited(_pickStartPointFromLibrary()),
        onEnterCoordinates: _enterStartPointCoordinates,
      );
    }
    final scheme = Theme.of(context).colorScheme;
    return CoordinateCard(
      // A rajthely nem pálya-elem: sorszám és fogantyú helyett zászló, és
      // nem húzható a bóják közé (ADR 0055 D1).
      rail: Icon(
        Icons.flag_outlined,
        size: 18,
        color: scheme.onSecondaryContainer,
      ),
      railColor: scheme.secondaryContainer,
      nameField: _nameField(
        l10n,
        startPoint,
        hint: l10n.setupStartPointNameLabel,
      ),
      latitudeField: _coordinateField(
        l10n,
        startPoint.latitudeController,
        GeoAxis.latitude,
      ),
      longitudeField: _coordinateField(
        l10n,
        startPoint.longitudeController,
        GeoAxis.longitude,
      ),
      removeTooltip: l10n.setupStartPointRemove,
      onRemove: () => _replaceStartPoint(null),
    );
  }

  /// A verseny neve: saját körvonalas mező (nem kártya), lebegő címkével,
  /// amely gépeléskor a keret vonalába csúszik (felhasználói döntés, UF).
  ///
  /// A keret és a kitöltés a téma `inputDecorationTheme`-jéből jön; mivel
  /// a keret minden állapotban outline, a szöveg fókuszváltáskor nem ugrik.
  Widget _raceNameField(AppLocalizations l10n) {
    final scheme = Theme.of(context).colorScheme;
    final style = supportTextStyle.copyWith(
      fontSize: 15,
      height: cardFieldLineHeight,
      color: scheme.onSurface,
    );
    final vertical = cardFieldVerticalPadding(
      context,
      style: style,
      height: _raceNameHeight,
    );
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: l10n.setupRaceNameLabel,
        labelStyle: const TextStyle(fontSize: 15),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: vertical,
        ),
      ),
      style: style,
      textInputAction: TextInputAction.next,
      validator: (value) => (value == null || value.trim().isEmpty)
          ? l10n.setupRaceNameRequired
          : null,
    );
  }

  /// A bója nélküli mód kapcsoló-kártyája (ADR 0046 Addendum 1 D7, 33a).
  ///
  /// A magyarázó sor **kikapcsolva is látszik**: a következmény (nincs
  /// bearing, ETA és predikció) különben a vízen derülne ki.
  Widget _marklessCard(AppLocalizations l10n) {
    final scheme = Theme.of(context).colorScheme;
    // A foretackTheme regisztrálja a TextTones-t → a fában mindig jelen van.
    final tones = Theme.of(context).extension<TextTones>()!;

    return FormCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          spacing: 12,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 3,
                children: [
                  Text(
                    l10n.setupNoMarksToggle,
                    style: supportTextStyle.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                  Text(
                    l10n.setupNoMarksHint,
                    style: supportTextStyle.copyWith(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                      color: tones.low,
                    ),
                  ),
                ],
              ),
            ),
            ForetackSwitch(
              value: _isMarkless,
              onChanged: (value) => setState(() => _isMarkless = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _padded(Widget child) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: _sideMargin),
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheduledStartAt = _scheduledStartAt;

    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Nem lusta ListView: a Form.validate() csak a fában lévő mezőket
          // futtatja, egy kigörgetett (lebontott) kártya pedig validálatlanul
          // jutna a submitig. A kártyák száma kicsi, így az egyszerre
          // felépített oszlop olcsó.
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _padded(_raceNameField(l10n)),
                  const SizedBox(height: _cardGap),
                  _padded(
                    StartTimeCard(
                      label: l10n.setupStartTimeLabel,
                      value: scheduledStartAt == null
                          ? null
                          : formatScheduledStart(
                              l10n,
                              scheduledStartAt.toLocal(),
                            ),
                      emptyLabel: l10n.setupStartTimeEmpty,
                      note: _startTimeNote(l10n),
                      clearTooltip: l10n.setupStartTimeClear,
                      onOpen: () => unawaited(_openStartTime()),
                      onClear: _clearStartTime,
                    ),
                  ),
                  const SizedBox(height: _cardGap),
                  _padded(_marklessCard(l10n)),
                  FormSectionHeader(label: l10n.setupStartPointSection),
                  _padded(_startPointSection(l10n)),
                  if (!_isMarkless) ...[
                    FormSectionHeader(
                      label: l10n.setupMarksSection,
                      count: _markRows.length,
                    ),
                    // A kártyák átrendezhetők; a ReorderableListView a külső
                    // görgetőn belül zsugorodik és nem görget külön.
                    ReorderableListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: _sideMargin,
                      ),
                      buildDefaultDragHandles: false,
                      onReorder: _reorderMarkRow,
                      children: [
                        for (var i = 0; i < _markRows.length; i++)
                          _markCard(l10n, i),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Bója nélküli módban nincs mit hozzáadni: a sáv egyetlen, teljes
          // szélességű Mentés gombra esik (ADR 0046 D4).
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
                      onTap: () => unawaited(_pickMarkFromLibrary()),
                    ),
                  ],
          ),
        ],
      ),
    );
  }
}

/// Egy bója- vagy rajthely-kártya szerkeszthető mezőinek kontrollerei.
class _PointControllers {
  _PointControllers({
    String name = '',
    String latitude = '',
    String longitude = '',
    this.shouldFocusName = false,
  }) : nameController = TextEditingController(text: name),
       latitudeController = TextEditingController(text: latitude),
       longitudeController = TextEditingController(text: longitude);

  /// Egy meglévő bójából, rajthelyből vagy könyvtár-elemből tölt fel.
  ///
  /// A koordináta tizedes fokként kerül a mezőbe, mint a részleten (U6).
  factory _PointControllers.fromPosition(String name, Coordinate position) =>
      _PointControllers(
        name: name,
        latitude: position.latitude.toString(),
        longitude: position.longitude.toString(),
      );

  final TextEditingController nameController;
  final TextEditingController latitudeController;
  final TextEditingController longitudeController;

  /// Igaz, ha a név-mező a megjelenéskor fókuszt kap („Koordináta" út).
  final bool shouldFocusName;

  /// A validált mezőkből a pozíció.
  Coordinate position() => Coordinate.checked(
    latitude: _degrees(latitudeController.text, GeoAxis.latitude),
    longitude: _degrees(longitudeController.text, GeoAxis.longitude),
  );

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
