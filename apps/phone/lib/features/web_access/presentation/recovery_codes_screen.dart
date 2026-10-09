import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/features/web_access/presentation/widgets/web_action_button.dart';
import 'package:phone/features/web_access/presentation/widgets/web_bottom_bar.dart';
import 'package:phone/l10n/app_localizations.dart';

/// A 10 helyreállító kód, egyszer (ADR 0051 D6, makett 18g, Addendum 8
/// V8).
///
/// A kódok csak memóriában vannak: ha a képernyő bezárul, elvesznek, és
/// újakat az app „Fiók és biztonság" képernyője (A5) vagy a CLI-s
/// újraregisztráció ad. Ezért nincs vissza-gomb és vissza-gesztus; az
/// „Elmentettem" zár.
class RecoveryCodesScreen extends StatelessWidget {
  /// A [codes] kódok képernyője.
  const RecoveryCodesScreen({required this.codes, super.key});

  /// A szerver által kiadott kódok, sorrendben.
  final List<String> codes;

  Future<void> _copy(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    // A `MaterialApp` regisztrálja a delegátorokat, ezért nem `null`.
    final copied = AppLocalizations.of(context)!.webCodesCopied;
    await Clipboard.setData(ClipboardData(text: codes.join('\n')));
    messenger.showSnackBar(SnackBar(content: Text(copied)));
  }

  @override
  Widget build(BuildContext context) {
    // A delegátorokat a `MaterialApp`, a `WarningColors`-t a
    // `foretackTheme` regisztrálja, így egyik sem `null`.
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final warning = Theme.of(context).extension<WarningColors>()!.warning;
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(l10n.webCodesTitle, style: screenTitleStyle),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          children: [
            ColoredBox(
              color: scheme.surfaceContainer,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 10,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: SizedBox.square(
                        dimension: 8,
                        child: ColoredBox(color: warning),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        l10n.webCodesNote,
                        style: supportTextStyle.copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            for (var row = 0; row < codes.length; row += 2)
              _CodeRow(
                first: (index: row, code: codes[row]),
                second: row + 1 < codes.length
                    ? (index: row + 1, code: codes[row + 1])
                    : null,
              ),
          ],
        ),
        bottomNavigationBar: WebBottomBar(
          children: [
            WebActionButton.secondary(
              label: l10n.webCodesCopy,
              onPressed: () => unawaited(_copy(context)),
            ),
            WebActionButton.primary(
              label: l10n.webCodesSaved,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

typedef _NumberedCode = ({int index, String code});

class _CodeRow extends StatelessWidget {
  const _CodeRow({required this.first, required this.second});

  final _NumberedCode first;
  final _NumberedCode? second;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final secondCode = second;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(child: _Code(code: first)),
            Expanded(
              child: secondCode == null
                  ? const SizedBox.shrink()
                  : _Code(code: secondCode),
            ),
          ],
        ),
      ),
    );
  }
}

class _Code extends StatelessWidget {
  const _Code({required this.code});

  final _NumberedCode code;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // A `foretackTheme` regisztrálja a `TextTones`-t.
    final tones = Theme.of(context).extension<TextTones>()!;
    final number = '${code.index + 1}'.padLeft(2, '0');
    return Row(
      spacing: 8,
      children: [
        Text(number, style: numeralCaptionStyle.copyWith(color: tones.low)),
        // Keskeny kijelzőn kicsinyít, de sosem vág le: egy csonka kód
        // használhatatlan.
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              code.code,
              style: numeralMicroStyle.copyWith(color: scheme.onSurface),
            ),
          ),
        ),
      ],
    );
  }
}
