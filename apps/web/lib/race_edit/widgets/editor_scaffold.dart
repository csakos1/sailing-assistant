import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:foretack_web/app/web_app_bar.dart';
import 'package:foretack_web/app/web_layout.dart';
import 'package:foretack_web/l10n/web_localizations.dart';

/// A szerkesztők közös kerete (ADR 0048 Addendum 1 G4, Addendum 4 K15).
///
/// AppBar vissza-gombbal, az űrlap a 640 px-es mértékben a 880 px-es
/// oszlopon belül, és a ragadós alsó sáv a Mentés gombbal (E7).
///
/// A kilépés (vissza-nyíl, Esc) mentetlen változtatásnál a 13o
/// dialógusát nyitja; mentetlenség nélkül azonnal visszalép. A sikeres
/// mentés után a hívó közvetlenül `Navigator.pop`-pal zár, ami a
/// dialógust megkerüli.
class EditorScaffold extends StatelessWidget {
  /// Keret a [title] címmel és a [children] űrlap-elemekkel.
  const EditorScaffold({
    required this.title,
    required this.children,
    required this.isSaving,
    required this.onSave,
    required this.hasUnsavedChanges,
    this.header,
    this.saveError,
    this.actions = const [],
    this.hasAutofocusField = false,
    super.key,
  });

  /// Az AppBar címe.
  final String title;

  /// Az AppBar jobb szélének gombjai (pl. a kuka).
  final List<Widget> actions;

  /// A teljes oszlop-szélességű fejléc az űrlap fölött (kontextus-sáv).
  final Widget? header;

  /// Az űrlap szakaszai, fentről lefelé.
  final List<Widget> children;

  /// Fut-e a mentés: a gomb ilyenkor tiltott és pörög.
  final bool isSaving;

  /// A Mentés gomb.
  final VoidCallback onSave;

  /// A mentés hibája a gomb fölött, ha van.
  final String? saveError;

  /// Van-e mentetlen változtatás (a kilépéskor kérdezzük).
  final bool Function() hasUnsavedChanges;

  /// Kér-e egy mező saját kezdő fókuszt (pl. az új verseny neve). Ha nem,
  /// a keret maga kapja, hogy az Esc mező-kattintás nélkül is működjön.
  final bool hasAutofocusField;

  @override
  Widget build(BuildContext context) {
    final header = this.header;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_leave(context));
      },
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): () =>
              unawaited(Navigator.of(context).maybePop()),
        },
        // A CallbackShortcuts csak a fókusz alatti billentyűket kapja meg.
        child: Focus(
          autofocus: !hasAutofocusField,
          // Láthatatlan, ezért a Tab nem áll meg rajta.
          skipTraversal: true,
          child: Scaffold(
            appBar: WebAppBar(title: title, showBack: true, actions: actions),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: WebLayout.columnMaxWidth,
                      ),
                      child: ListView(
                        padding: const EdgeInsets.only(bottom: 48),
                        children: [
                          ?header,
                          Align(
                            alignment: Alignment.topLeft,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: WebLayout.textMaxWidth,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: WebLayout.columnInset,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: children,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                _SaveBar(isSaving: isSaving, onSave: onSave, error: saveError),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _leave(BuildContext context) async {
    final navigator = Navigator.of(context);
    if (!hasUnsavedChanges()) {
      navigator.pop();
      return;
    }
    final l10n = WebLocalizations.of(context)!;
    final shouldDiscard = await showForetackDialog<bool>(
      context: context,
      title: l10n.editDiscardTitle,
      message: l10n.editDiscardMessage,
      maxWidth: WebLayout.dialogWidth,
      actions: [
        ForetackDialogAction(label: l10n.editDiscardKeep, value: false),
        ForetackDialogAction(
          label: l10n.editDiscardConfirm,
          value: true,
          isDestructive: true,
        ),
      ],
    );
    if (shouldDiscard ?? false) navigator.pop();
  }
}

/// A ragadós alsó sáv a Mentés gombbal (E7: 58 px, oszlopszélesen).
class _SaveBar extends StatelessWidget {
  const _SaveBar({
    required this.isSaving,
    required this.onSave,
    required this.error,
  });

  final bool isSaving;
  final VoidCallback onSave;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final l10n = WebLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final error = this.error;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Align(
        alignment: Alignment.topCenter,
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: WebLayout.columnMaxWidth,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: WebLayout.columnInset,
              vertical: 14,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (error != null) ...[
                  Text(
                    error,
                    style: supportTextStyle.copyWith(color: scheme.error),
                  ),
                  const SizedBox(height: 10),
                ],
                SizedBox(
                  height: WebLayout.saveButtonHeight,
                  child: FilledButton(
                    onPressed: isSaving ? null : onSave,
                    style: FilledButton.styleFrom(
                      shape: const RoundedRectangleBorder(),
                      textStyle: supportTextStyle.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: isSaving
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.editSave),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
