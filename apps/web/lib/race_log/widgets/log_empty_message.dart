import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:foretack_web/app/web_layout.dart';
import 'package:foretack_web/auth/session_provider.dart';
import 'package:foretack_web/l10n/web_localizations.dart';

/// Az üres archívum szövege (13b), a napló és a Statisztika-képernyő
/// közepén. A legénység feltöltésre hívás nélküli változatot kap (ADR
/// 0051 Addendum 7 P7).
///
/// A `WebLocalizations.of(context)!` biztonságos: a `MaterialApp`
/// regisztrálja a delegátorokat.
class LogEmptyMessage extends ConsumerWidget {
  /// Az üres archívum szövege.
  const LogEmptyMessage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Center(
    child: Padding(
      padding: const EdgeInsets.all(WebLayout.columnInset),
      child: Text(
        ref.watch(isOwnerProvider)
            ? WebLocalizations.of(context)!.logEmpty
            : WebLocalizations.of(context)!.logEmptyCrew,
        style: supportTextStyle,
        textAlign: TextAlign.center,
      ),
    ),
  );
}
