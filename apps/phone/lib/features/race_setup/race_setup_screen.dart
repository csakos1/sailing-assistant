import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:phone/providers/id_provider.dart';
import 'package:phone/providers/race_repository_provider.dart';
import 'package:shared/shared.dart';

/// Új verseny felvitele: név + dinamikus bója-sorok (sorszám automatikus,
/// név + lat/lon decimális fokban).
///
/// Mentéskor a `Race.create` factory készíti a versenyt, majd a
/// `raceRepositoryProvider` perzisztálja. v1: csak létrehozás (create-only).
/// A lat/lon-t a domain `Coordinate.tryFromDegrees`-e validálja — a UI nem
/// duplikálja a megengedett tartományt. Az `AppLocalizations.of(context)!`
/// biztonságos: a `MaterialApp` regisztrálja a delegátorokat.
class RaceSetupScreen extends ConsumerStatefulWidget {
  const RaceSetupScreen({super.key});

  @override
  ConsumerState<RaceSetupScreen> createState() => _RaceSetupScreenState();
}

class _RaceSetupScreenState extends ConsumerState<RaceSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  // A Race ctor a nemüres marks-ot asserteli, ezért egy sorral indulunk,
  // és az utolsó sort nem engedjük törölni.
  final _markRows = <_MarkRowControllers>[_MarkRowControllers()];

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

  Future<void> _save() async {
    // A Form a fában van, így a currentState garantáltan nem null.
    if (!_formKey.currentState!.validate()) return;

    final marks = <Mark>[
      for (var i = 0; i < _markRows.length; i++)
        Mark(
          sequence: i + 1,
          name: _markRows[i].nameController.text.trim(),
          // A validáció után a lat/lon garantáltan érvényes tartomány.
          position: Coordinate.checked(
            latitude: double.parse(_markRows[i].latitudeController.text),
            longitude: double.parse(_markRows[i].longitudeController.text),
          ),
        ),
    ];

    final race = Race.create(
      id: ref.read(idProvider)(),
      name: _nameController.text.trim(),
      marks: marks,
    );
    await ref.read(raceRepositoryProvider).save(race);

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.setupTitle)),
      body: Form(
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
            for (var i = 0; i < _markRows.length; i++)
              _MarkRowFields(
                key: ObjectKey(_markRows[i]),
                l10n: l10n,
                controllers: _markRows[i],
                number: i + 1,
                onRemove: _markRows.length > 1 ? () => _removeMarkRow(i) : null,
              ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _addMarkRow,
              icon: const Icon(Icons.add),
              label: Text(l10n.setupAddMark),
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _save, child: Text(l10n.setupSave)),
          ],
        ),
      ),
    );
  }
}

/// Egy bója-sor szerkeszthető mezőinek kontroller-csoportja.
class _MarkRowControllers {
  final nameController = TextEditingController();
  final latitudeController = TextEditingController();
  final longitudeController = TextEditingController();

  void dispose() {
    nameController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
  }
}

/// Egy bója-sor megjelenítése: sorszám-fejléc, név/lat/lon mezők, és
/// (egynél több sornál) törlés gomb.
class _MarkRowFields extends StatelessWidget {
  const _MarkRowFields({
    required this.l10n,
    required this.controllers,
    required this.number,
    required this.onRemove,
    super.key,
  });

  final AppLocalizations l10n;
  final _MarkRowControllers controllers;
  final int number;
  final VoidCallback? onRemove;

  String? _validateName(String? value) =>
      (value == null || value.trim().isEmpty)
      ? l10n.setupMarkNameRequired
      : null;

  String? _validateLatitude(String? value) {
    final parsed = double.tryParse(value ?? '');
    if (parsed == null) return l10n.setupInvalidNumber;
    return switch (Coordinate.tryFromDegrees(latitude: parsed, longitude: 0)) {
      Ok() => null,
      Err() => l10n.setupLatitudeOutOfRange,
    };
  }

  String? _validateLongitude(String? value) {
    final parsed = double.tryParse(value ?? '');
    if (parsed == null) return l10n.setupInvalidNumber;
    return switch (Coordinate.tryFromDegrees(latitude: 0, longitude: parsed)) {
      Ok() => null,
      Err() => l10n.setupLongitudeOutOfRange,
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
