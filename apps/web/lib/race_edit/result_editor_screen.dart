import 'dart:async';

import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:foretack_web/app/web_layout.dart';
import 'package:foretack_web/app/web_snack_bar.dart';
import 'package:foretack_web/auth/session_provider.dart';
import 'package:foretack_web/l10n/web_localizations.dart';
import 'package:foretack_web/race_edit/editor_problems.dart';
import 'package:foretack_web/race_edit/field_problem_text.dart';
import 'package:foretack_web/race_edit/form/field_problem.dart';
import 'package:foretack_web/race_edit/form/form_text_parsers.dart';
import 'package:foretack_web/race_edit/form/local_instant.dart';
import 'package:foretack_web/race_edit/form/read_result_form.dart';
import 'package:foretack_web/race_edit/form/result_form_values.dart';
import 'package:foretack_web/race_edit/race_record_editor.dart';
import 'package:foretack_web/race_edit/result_form_fields.dart';
import 'package:foretack_web/race_edit/widgets/editor_scaffold.dart';
import 'package:foretack_web/race_edit/widgets/official_times_section.dart';
import 'package:foretack_web/race_edit/widgets/prize_and_summary_section.dart';
import 'package:foretack_web/race_edit/widgets/result_placings_section.dart';
import 'package:foretack_web/race_edit/widgets/telemetry_editor_header.dart';
import 'package:foretack_web/race_log/race_log_providers.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';

/// Egy telemetriás verseny eredmény-szerkesztője (ADR 0048 Addendum 1
/// G4, Addendum 4 K11, K15).
///
/// A részletező ceruzájáról nyílik, a betöltött napló-sorral. Mentés után
/// visszalép a részletezőre, és „Eredmény mentve" snackbart mutat. A
/// tulajdonos innen a versenyt végleg törölheti (ADR 0057 D3).
class ResultEditorScreen extends ConsumerStatefulWidget {
  /// Szerkesztő a [summary] telemetriás versenyhez.
  const ResultEditorScreen({
    required this.summary,
    required this.recording,
    super.key,
  });

  /// A verseny napló-sora: név, azonosító és a tárolt eredmény.
  final RaceSummary summary;

  /// A rögzítés ablaka (a `TelemetryOrigin`-ból).
  final TimeWindow recording;

  @override
  ConsumerState<ResultEditorScreen> createState() => _ResultEditorState();
}

class _ResultEditorState extends ConsumerState<ResultEditorScreen> {
  late final ResultFormValues _initialValues;
  late final ResultFormFields _fields;
  List<FieldProblem> _problems = const [];
  SaveFailureMessage? _saveFailure;
  bool _isDeleteFailed = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final content = widget.summary.result?.content;
    // A rajt napja a tárolt hivatalos rajté, különben a rögzítés kezdetéé.
    final startDate = localDateOf(
      content?.officialStart ?? widget.recording.start,
    );
    _initialValues = resultFormValuesOf(content, startDate: startDate);
    _fields = ResultFormFields(_initialValues);
  }

  @override
  void dispose() {
    _fields.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = WebLocalizations.of(context)!;
    final saveFailure = _saveFailure;

    return EditorScaffold(
      title: l10n.editResultTitle,
      header: TelemetryEditorHeader(
        name: widget.summary.name,
        recording: widget.recording,
      ),
      actions: [
        // A szerkesztő csak a tulajdonos ceruzájáról nyílik; a törlés így is
        // a szerepet nézi (ADR 0051 Addendum 7 P7).
        if (ref.watch(isOwnerProvider))
          IconButton(
            tooltip: l10n.editDeleteTooltip,
            icon: const Icon(Icons.delete_outline),
            onPressed: _isSaving ? null : () => unawaited(_confirmDelete()),
          ),
      ],
      isSaving: _isSaving,
      onSave: () => unawaited(_save()),
      saveError: _isDeleteFailed
          ? l10n.editDeleteFailed
          : saveFailure == null
          ? null
          : saveFailureText(l10n, saveFailure),
      hasUnsavedChanges: () => _fields.values != _initialValues,
      children: [
        ResultPlacingsSection(fields: _fields, problems: _problems),
        OfficialTimesSection(
          fields: _fields,
          problems: _problems,
          showsStartDate: true,
        ),
        PrizeAndSummarySection(fields: _fields),
      ],
    );
  }

  Future<void> _save() async {
    switch (readResultForm(_fields.values)) {
      case Err(:final error):
        _showProblems(error);
      case Ok(:final value):
        await _submit(value);
    }
  }

  Future<void> _submit(RaceResultInput input) async {
    setState(() {
      _isSaving = true;
      _saveFailure = null;
      _isDeleteFailed = false;
    });
    final result = await ref
        .read(raceRecordEditorProvider)
        .saveResult(widget.summary.id, input);
    if (!mounted) return;
    switch (result) {
      case Ok():
        _closeWithSnackBar();
      case Err(:final error):
        final view = viewOfSaveFailure(error);
        setState(() {
          _isSaving = false;
          _saveFailure = view.message;
        });
        if (view.problems.isNotEmpty) _showProblems(view.problems);
    }
  }

  void _showProblems(List<FieldProblem> problems) {
    setState(() => _problems = problems);
    final first = firstProblemInFormOrder(problems);
    if (first == null) return;
    _fields.focusNodeFor(first, showsStartDate: true)?.requestFocus();
  }

  Future<void> _confirmDelete() async {
    final l10n = WebLocalizations.of(context)!;
    final shouldDelete = await showForetackDialog<bool>(
      context: context,
      title: l10n.editDeleteTitle,
      message: l10n.editDeleteTelemetryMessage,
      maxWidth: WebLayout.dialogWidth,
      details: [
        (label: l10n.editDeleteRowRace, value: widget.summary.name),
        (
          label: l10n.editDeleteRowDate,
          value: formatFormDate(localDateOf(widget.recording.start)),
        ),
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
    await _delete();
  }

  Future<void> _delete() async {
    setState(() {
      _isSaving = true;
      _saveFailure = null;
      _isDeleteFailed = false;
    });
    final result = await ref
        .read(raceRecordEditorProvider)
        .deleteTelemetryRace(widget.summary.id);
    if (!mounted) return;
    switch (result) {
      case Ok():
        final messenger = ScaffoldMessenger.of(context);
        final screenWidth = MediaQuery.sizeOf(context).width;
        final message = WebLocalizations.of(context)!.snackRaceDeleted;
        // A napló a törölt verseny évén nyílik (ADR 0048 Addendum 4 K15).
        ref
            .read(logPeriodProvider.notifier)
            .chooseYear(localDateOf(widget.recording.start).year);
        Navigator.of(context).popUntil((route) => route.isFirst);
        showWebSnackBar(messenger, message: message, screenWidth: screenWidth);
      case Err():
        setState(() {
          _isSaving = false;
          _isDeleteFailed = true;
        });
    }
  }

  void _closeWithSnackBar() {
    // A snackbar a gyökér ScaffoldMessengerén a részletezőn is látszik,
    // ezért a kiolvasás a bezárás előtt történik.
    final messenger = ScaffoldMessenger.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final message = WebLocalizations.of(context)!.snackResultSaved;
    Navigator.of(context).pop();
    showWebSnackBar(messenger, message: message, screenWidth: screenWidth);
  }
}
