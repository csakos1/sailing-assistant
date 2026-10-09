import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:foretack_web/app/leave_warning_scope.dart';
import 'package:foretack_web/app/web_layout.dart';
import 'package:foretack_web/l10n/web_localizations.dart';
import 'package:foretack_web/race_import/file_size_format.dart';
import 'package:foretack_web/race_import/import_dialog_state.dart';
import 'package:foretack_web/race_import/import_failure_text.dart';
import 'package:foretack_web/race_import/import_providers.dart';
import 'package:foretack_web/race_import/import_result_groups.dart';
import 'package:foretack_web/race_import/import_uploader.dart';
import 'package:foretack_web/race_import/picked_file.dart';
import 'package:foretack_web/race_import/widgets/import_dialog_heading.dart';
import 'package:foretack_web/race_import/widgets/import_file_cell.dart';
import 'package:foretack_web/race_import/widgets/import_progress_line.dart';
import 'package:foretack_web/race_import/widgets/import_result_list.dart';
import 'package:foretack_web/race_log/race_log_providers.dart';
import 'package:race_archive_api/race_archive_api.dart';

/// Megnyitja a feltöltés-dialógust (ADR 0047 E8, ADR 0048 Addendum 4
/// K19–K21), és bezáráskor frissíti a naplót, ha az import sikerült
/// (13i).
///
/// A konténert a megnyitás előtt olvassuk ki: a bezárás után a hívó
/// képernyő kontextusa már nem biztos, hogy él.
Future<void> showImportDialog(BuildContext context) async {
  final container = ProviderScope.containerOf(context, listen: false);
  var hasImported = false;
  await showForetackDialogFrame<void>(
    context: context,
    builder: (_) => ImportDialog(onImported: () => hasImported = true),
  );
  if (hasImported) container.invalidate(raceSummariesProvider);
}

/// A feltöltés-dialógus tartalma (13f–13j).
///
/// Az állapot az [ImportDialogState] pure gépe; ez a widget a
/// mellékhatásokat végzi: a fájlválasztót, a feltöltőt és a bezárást. A
/// bezárás (Mégse, Esc, háttér) feltöltés közben megszakítja az XHR-t
/// (K20): a `dispose` hívja a `cancel`-t.
class ImportDialog extends ConsumerStatefulWidget {
  /// Dialógus; az [onImported] egy sikeres import után fut.
  const ImportDialog({required this.onImported, super.key});

  /// Sikeres import után hívódik, hogy a hívó bezáráskor frissítsen.
  final VoidCallback onImported;

  @override
  ConsumerState<ImportDialog> createState() => _ImportDialogViewState();
}

class _ImportDialogViewState extends ConsumerState<ImportDialog> {
  ImportDialogState _state = const ChoosingFiles();
  ImportUpload? _runningUpload;
  final FocusNode _uploadActionFocus = FocusNode();

  @override
  void dispose() {
    _runningUpload?.cancel();
    _uploadActionFocus.dispose();
    super.dispose();
  }

  Future<void> _pickDatabase() async {
    final file = await _pickFile();
    final state = _state;
    if (file == null || state is! ChoosingFiles) return;
    setState(() => _state = state.withDatabase(file));
    // A fő fájl után az Enter már indíthat (13f). A fókusz csak az
    // újraépítés után kérhető: addig a cella még tiltott, és a kérést
    // csendben eldobná.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _uploadActionFocus.requestFocus();
    });
  }

  Future<void> _pickWal() async {
    final file = await _pickFile();
    final state = _state;
    if (file == null || state is! ChoosingFiles) return;
    setState(() => _state = state.withWal(file));
  }

  Future<PickedFile?> _pickFile() async {
    final file = await ref.read(importFilePickerProvider)();
    // A választó a dialógus bezárása után is visszatérhet.
    return mounted ? file : null;
  }

  Future<void> _startUpload() async {
    final choosing = _state;
    if (choosing is! ChoosingFiles) return;
    final uploading = choosing.startUpload();
    if (uploading == null) return;
    setState(() => _state = uploading);

    final upload = ref.read(importUploaderProvider)(
      database: uploading.database,
      wal: uploading.wal,
      onProgress: _onProgress,
    );
    _runningUpload = upload;
    final outcome = await upload.result;
    _runningUpload = null;
    final state = _state;
    if (!mounted || state is! Uploading) return;

    final next = state.finish(outcome);
    setState(() => _state = next);
    if (next is ImportFinished) widget.onImported();
  }

  void _onProgress(int sentBytes, int totalBytes) {
    final state = _state;
    if (!mounted || state is! Uploading) return;
    setState(() => _state = state.withProgress(sentBytes, totalBytes));
  }

  void _close() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final state = _state;
    return LeaveWarningScope(
      // Futó feltöltésnél a fül bezárása megszakítaná az XHR-t (K24).
      shouldWarn: _isUploading,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: WebLayout.dialogWidth),
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: switch (state) {
                ChoosingFiles() => _choosing(state),
                Uploading() => _uploading(state),
                ImportFinished() => _finished(state),
                SchemaRejected() => _schemaRejected(state),
              },
            ),
            if (state is Uploading)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ImportProgressLine(fraction: state.fraction),
              ),
          ],
        ),
      ),
    );
  }

  bool _isUploading() => _state is Uploading;

  List<Widget> _choosing(ChoosingFiles state) {
    final l10n = WebLocalizations.of(context)!;
    final failure = state.failure;
    return [
      _Body(
        heading: ImportDialogHeading(title: l10n.importTitle),
        message: l10n.importMessage,
        children: [
          _FileCells(
            database: ImportFileCell(
              label: l10n.importDatabaseLabelCaps,
              file: state.database,
              autofocus: state.database == null,
              onPressed: () => unawaited(_pickDatabase()),
            ),
            wal: ImportFileCell(
              label: l10n.importWalLabelCaps,
              file: state.wal,
              onPressed: () => unawaited(_pickWal()),
            ),
          ),
          if (failure != null) ...[
            const SizedBox(height: 14),
            Text(
              importFailureText(l10n, failure),
              style: supportTextStyle.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ],
      ),
      ForetackDialogActionBar(
        cells: [
          ForetackDialogActionCell(label: l10n.importCancel, onPressed: _close),
          ForetackDialogActionCell(
            label: l10n.importStart,
            focusNode: _uploadActionFocus,
            onPressed: state.canUpload ? () => unawaited(_startUpload()) : null,
          ),
        ],
      ),
    ];
  }

  List<Widget> _uploading(Uploading state) {
    final l10n = WebLocalizations.of(context)!;
    final wal = state.wal;
    return [
      _Body(
        heading: ImportDialogHeading(
          title: l10n.importTitle,
          trailing: Text(
            state.isProcessing
                ? l10n.importProcessingCaps
                : l10n.importPercent((state.fraction * 100).floor()),
            style: statusLabelStyle.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        message: l10n.importMessage,
        children: [
          _FileCells(
            database: ImportFileCell(
              label: l10n.importDatabaseLabelCaps,
              file: state.database,
              sizeText: formatSentOfTotal(
                state.databaseSentBytes,
                state.database.sizeBytes,
              ),
              onPressed: null,
            ),
            wal: ImportFileCell(
              label: l10n.importWalLabelCaps,
              file: wal,
              onPressed: null,
            ),
          ),
        ],
      ),
      ForetackDialogActionBar(
        cells: [
          ForetackDialogActionCell(label: l10n.importCancel, onPressed: _close),
          ForetackDialogActionCell(
            label: l10n.importUploading,
            isBusy: true,
            onPressed: null,
          ),
        ],
      ),
    ];
  }

  List<Widget> _finished(ImportFinished state) {
    final l10n = WebLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final tones = Theme.of(context).extension<TextTones>()!;
    final groups = importResultGroupsOf(state.report);
    final isWalIgnored = state.report.warnings.contains(
      ImportWarning.walIgnored,
    );
    return [
      _Body(
        heading: ImportDialogHeading(
          title: l10n.importDoneTitle,
          trailing: _StatusSquare(color: scheme.onSurfaceVariant),
        ),
        message: l10n.importDoneMessage,
        bottomPadding: groups.isEmpty ? 18 : 14,
        children: [
          if (isWalIgnored) ...[
            const SizedBox(height: 8),
            Text(
              l10n.importWalIgnored,
              style: supportTextStyle.copyWith(
                fontSize: 12,
                color: tones.low,
              ),
            ),
          ],
          if (groups.isEmpty) ...[
            const SizedBox(height: 14),
            Text(
              l10n.importNothingFound,
              style: supportTextStyle.copyWith(color: scheme.onSurface),
            ),
          ],
        ],
      ),
      if (groups.isNotEmpty) ImportResultList(groups: groups),
      _CloseBar(onPressed: _close),
    ];
  }

  List<Widget> _schemaRejected(SchemaRejected state) {
    final l10n = WebLocalizations.of(context)!;
    return [
      _Body(
        heading: ImportDialogHeading(
          title: l10n.importSchemaTitle,
          trailing: _StatusSquare(
            color: Theme.of(context).colorScheme.error,
          ),
        ),
        message: l10n.importSchemaMessage,
        children: [
          const SizedBox(height: 16),
          ForetackDialogDetailCell(
            details: [
              (
                label: state.fileName,
                value: l10n.importSchemaVersionCaps(state.fileVersion),
              ),
              (
                label: l10n.importSchemaServer,
                value: l10n.importSchemaVersionCaps(state.serverVersion),
              ),
            ],
          ),
        ],
      ),
      _CloseBar(onPressed: _close),
    ];
  }
}

/// A doboz felső része: címsor, magyarázat és az állapot elemei (11a
/// betétei).
class _Body extends StatelessWidget {
  const _Body({
    required this.heading,
    required this.message,
    required this.children,
    this.bottomPadding = 18,
  });

  final Widget heading;
  final String message;
  final List<Widget> children;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(20, 22, 20, bottomPadding),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        heading,
        const SizedBox(height: 12),
        Text(
          message,
          style: supportTextStyle.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        ...children,
      ],
    ),
  );
}

/// A két fájl-cella a WAL-magyarázattal (13f).
class _FileCells extends StatelessWidget {
  const _FileCells({required this.database, required this.wal});

  final Widget database;
  final Widget wal;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: 20),
      database,
      const SizedBox(height: 20),
      wal,
      const SizedBox(height: 7),
      Padding(
        padding: const EdgeInsets.only(left: 14),
        child: Text(
          WebLocalizations.of(context)!.importWalHint,
          style: supportTextStyle.copyWith(
            fontSize: 11.5,
            color: Theme.of(context).extension<TextTones>()!.low,
          ),
        ),
      ),
    ],
  );
}

/// Az egyetlen, teljes szélességű Bezárás akció kezdő fókusszal (13i,
/// 13j).
class _CloseBar extends StatelessWidget {
  const _CloseBar({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => ForetackDialogActionBar(
    cells: [
      ForetackDialogActionCell(
        label: WebLocalizations.of(context)!.importClose,
        autofocus: true,
        onPressed: onPressed,
      ),
    ],
  );
}

/// A címsor 8 px-es státusznégyzete: kész (13i) vagy hiba (13j).
class _StatusSquare extends StatelessWidget {
  const _StatusSquare({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 8,
    child: ColoredBox(color: color),
  );
}
