import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:foretack_web/app/web_layout.dart';
import 'package:foretack_web/app/web_snack_bar.dart';
import 'package:foretack_web/l10n/web_localizations.dart';
import 'package:foretack_web/race_detail/race_detail_screen.dart';
import 'package:foretack_web/race_edit/editor_problems.dart';
import 'package:foretack_web/race_edit/field_problem_text.dart';
import 'package:foretack_web/race_edit/form/field_problem.dart';
import 'package:foretack_web/race_edit/form/manual_race_form_values.dart';
import 'package:foretack_web/race_edit/form/read_manual_race_form.dart';
import 'package:foretack_web/race_edit/form/track_computed_stats.dart';
import 'package:foretack_web/race_edit/manual_race_form_fields.dart';
import 'package:foretack_web/race_edit/race_record_editor.dart';
import 'package:foretack_web/race_edit/result_form_fields.dart';
import 'package:foretack_web/race_edit/widgets/distance_and_wind_section.dart';
import 'package:foretack_web/race_edit/widgets/editor_scaffold.dart';
import 'package:foretack_web/race_edit/widgets/manual_editor_header.dart';
import 'package:foretack_web/race_edit/widgets/official_times_section.dart';
import 'package:foretack_web/race_edit/widgets/prize_and_summary_section.dart';
import 'package:foretack_web/race_edit/widgets/race_identity_section.dart';
import 'package:foretack_web/race_edit/widgets/result_placings_section.dart';
import 'package:foretack_web/race_log/race_log_providers.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';

/// A kézi verseny szerkesztője: „Új verseny" vagy „Verseny szerkesztése"
/// (ADR 0048 Addendum 1 G4–G5, Addendum 4 K11–K15).
///
/// A [summary] nélkül üres űrlappal nyílik, és a Mentés létrehozza a
/// versenyt: ekkor a szerkesztő helyén az új részletező nyílik. Egy
/// meglévő versenynél a Mentés visszalép a részletezőre, a kuka pedig
/// megerősítés után véglegesen töröl, és a naplóra visz.
class ManualRaceEditorScreen extends ConsumerStatefulWidget {
  /// Szerkesztő a [summary] kézi versenyhez; `null`-nál új verseny.
  const ManualRaceEditorScreen({this.summary, super.key});

  /// A szerkesztett verseny napló-sora, vagy `null` új versenynél.
  final RaceSummary? summary;

  @override
  ConsumerState<ManualRaceEditorScreen> createState() =>
      _ManualRaceEditorState();
}

class _ManualRaceEditorState extends ConsumerState<ManualRaceEditorScreen> {
  late final ManualEditorValues _initialValues;
  late final ManualRaceFormFields _raceFields;
  late final ResultFormFields _resultFields;
  List<FieldProblem> _problems = const [];
  String? _failureText;
  bool _isSaving = false;

  bool get _isNew => widget.summary == null;

  @override
  void initState() {
    super.initState();
    _initialValues = manualEditorValuesOf(widget.summary);
    _raceFields = ManualRaceFormFields(_initialValues.race);
    // A rajt napja a verseny dátuma: az eredmény ugyanazt a mezőt olvassa.
    _resultFields = ResultFormFields(
      _initialValues.result,
      sharedStartDate: _raceFields.date,
    );
  }

  @override
  void dispose() {
    _resultFields.dispose();
    _raceFields.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = WebLocalizations.of(context)!;

    return EditorScaffold(
      title: _isNew ? l10n.newRaceTitle : l10n.editManualTitle,
      header: const ManualEditorHeader(),
      actions: [
        if (!_isNew)
          IconButton(
            tooltip: l10n.editDeleteTooltip,
            icon: const Icon(Icons.delete_outline),
            onPressed: _isSaving ? null : () => unawaited(_confirmDelete()),
          ),
      ],
      isSaving: _isSaving,
      hasAutofocusField: _isNew,
      onSave: () => unawaited(_save()),
      saveError: _failureText,
      hasUnsavedChanges: () =>
          _raceFields.values != _initialValues.race ||
          _resultFields.values != _initialValues.result,
      children: [
        RaceIdentitySection(
          fields: _raceFields,
          problems: _problems,
          autofocusName: _isNew,
        ),
        ResultPlacingsSection(fields: _resultFields, problems: _problems),
        OfficialTimesSection(
          fields: _resultFields,
          problems: _problems,
          showsStartDate: false,
        ),
        DistanceAndWindSection(
          fields: _raceFields,
          resultFields: _resultFields,
          problems: _problems,
          computedStats: trackComputedStatsOf(widget.summary),
        ),
        PrizeAndSummarySection(fields: _resultFields),
      ],
    );
  }

  Future<void> _save() async {
    switch (readManualRaceForm(_raceFields.values, _resultFields.values)) {
      case Err(:final error):
        _showProblems(error);
      case Ok(:final value):
        await _submit(value);
    }
  }

  Future<void> _submit(ManualRaceRequest request) async {
    setState(() {
      _isSaving = true;
      _failureText = null;
    });
    final editor = ref.read(raceRecordEditorProvider);
    final summary = widget.summary;
    final result = summary == null
        ? await editor.createManualRace(request)
        : await editor.updateManualRace(summary.id, request);
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        _finishSave(value, request.race.date);
      case Err(:final error):
        final l10n = WebLocalizations.of(context)!;
        final view = viewOfSaveFailure(error);
        final message = view.message;
        setState(() {
          _isSaving = false;
          _failureText = message == null
              ? null
              : saveFailureText(l10n, message);
        });
        if (view.problems.isNotEmpty) _showProblems(view.problems);
    }
  }

  void _finishSave(RaceSummary saved, CalendarDate date) {
    final l10n = WebLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final navigator = Navigator.of(context);
    if (_isNew) {
      // A napló a verseny évére vált, hogy visszalépve ott legyen (K15).
      ref.read(logPeriodProvider.notifier).chooseYear(date.year);
      unawaited(
        navigator.pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) =>
                RaceDetailScreen(raceId: saved.id, raceName: saved.name),
          ),
        ),
      );
    } else {
      navigator.pop();
    }
    showWebSnackBar(
      messenger,
      message: _isNew ? l10n.snackRaceCreated : l10n.snackRaceSaved,
      screenWidth: screenWidth,
    );
  }

  Future<void> _confirmDelete() async {
    // A `!` biztonságos: a kuka csak meglévő versenynél látszik.
    final summary = widget.summary!;
    final l10n = WebLocalizations.of(context)!;
    final shouldDelete = await showForetackDialog<bool>(
      context: context,
      title: l10n.editDeleteTitle,
      message: l10n.editDeleteMessage,
      maxWidth: WebLayout.dialogWidth,
      details: [
        (label: l10n.editDeleteRowRace, value: summary.name),
        (label: l10n.editDeleteRowDate, value: _initialValues.race.date),
      ],
      actions: [
        ForetackDialogAction(label: l10n.editDeleteCancel, value: false),
        ForetackDialogAction(
          label: l10n.editDeleteConfirm,
          value: true,
          isDestructive: true,
        ),
      ],
    );
    if (!(shouldDelete ?? false) || !mounted) return;
    await _delete(summary);
  }

  Future<void> _delete(RaceSummary summary) async {
    setState(() {
      _isSaving = true;
      _failureText = null;
    });
    final result = await ref
        .read(raceRecordEditorProvider)
        .deleteManualRace(summary.id);
    if (!mounted) return;
    final l10n = WebLocalizations.of(context)!;
    switch (result) {
      case Ok():
        final messenger = ScaffoldMessenger.of(context);
        final screenWidth = MediaQuery.sizeOf(context).width;
        // A napló a törölt verseny évén nyílik (G5).
        if (summary.origin case ManualOrigin(:final date)) {
          ref.read(logPeriodProvider.notifier).chooseYear(date.year);
        }
        Navigator.of(context).popUntil((route) => route.isFirst);
        showWebSnackBar(
          messenger,
          message: l10n.snackRaceDeleted,
          screenWidth: screenWidth,
        );
      case Err():
        setState(() {
          _isSaving = false;
          _failureText = l10n.editDeleteFailed;
        });
    }
  }

  void _showProblems(List<FieldProblem> problems) {
    setState(() => _problems = problems);
    final first = firstProblemInFormOrder(problems);
    if (first == null) return;
    final node =
        _raceFields.focusNodeFor(first) ??
        _resultFields.focusNodeFor(first, showsStartDate: false);
    node?.requestFocus();
  }
}
