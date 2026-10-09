import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/features/web_access/application/join_submission.dart';
import 'package:phone/features/web_access/application/scan_problem.dart';
import 'package:phone/features/web_access/application/web_access_providers.dart';
import 'package:phone/features/web_access/data/web_account.dart';
import 'package:phone/features/web_access/presentation/web_access_log.dart';
import 'package:phone/features/web_access/presentation/web_access_prompts.dart';
import 'package:phone/features/web_access/presentation/widgets/web_action_button.dart';
import 'package:phone/features/web_access/presentation/widgets/web_bottom_bar.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';

/// A csatlakozási kérelem űrlapja (ADR 0051 D3, makett 18e, Addendum 8 V9,
/// Addendum 9 X1, X2, X6).
///
/// Egy névmező és a „Kérelem küldése". A küldés a kulcsokat, az
/// ujjlenyomatot és a szerverhívást futtatja; az eredmény a beolvasóhoz
/// tér vissza (`JoinSubmitted` vagy `JoinFailed`). Egy elvetett
/// ujjlenyomat-ablak után a képernyő marad, a beírt névvel.
///
/// A nevet a beolvasó őrzi (X2): a mező minden változását az
/// [onNameChanged], a küldött nevet az [onNameSent] kapja meg.
class JoinRequestScreen extends ConsumerStatefulWidget {
  /// Űrlap a [payload] belépési kéréshez; az [initialName] egy megőrzött
  /// név (X2).
  const JoinRequestScreen({
    required this.payload,
    required this.onNameChanged,
    required this.onNameSent,
    this.initialName,
    super.key,
  });

  /// A beolvasott belépési QR.
  final LoginQrPayload payload;

  /// A mező kezdő szövege, ha van megőrzött név.
  final String? initialName;

  /// A mező szövege minden változáskor (a visszalépéshez a kamerára).
  final ValueChanged<String> onNameChanged;

  /// A normalizált név a küldés előtt (az azonnali újrapróbához).
  final ValueChanged<String> onNameSent;

  /// A felső korlát a mezőben: a szerver 40 kódpontot fogad el, de a
  /// gépelés közben ennél valamivel több is beférhet, hogy a hibasor
  /// látsszon, ne csak a gépelés álljon meg.
  static const int inputLimit = 60;

  @override
  ConsumerState<JoinRequestScreen> createState() => _JoinRequestScreenState();
}

class _JoinRequestScreenState extends ConsumerState<JoinRequestScreen> {
  late final TextEditingController _name = TextEditingController(
    text: widget.initialName,
  );
  bool _isSending = false;

  bool get _isNameValid => normalizeDisplayName(_name.text) != null;

  Future<void> _submit() async {
    final name = normalizeDisplayName(_name.text);
    if (_isSending || name == null) return;
    widget.onNameSent(name);
    setState(() => _isSending = true);
    final prompt = joinPromptText(
      // A `MaterialApp` regisztrálja a delegátorokat, ezért nem `null`.
      AppLocalizations.of(context)!,
      widget.payload.origin,
    );
    final JoinSubmission submission;
    try {
      final result = await ref
          .read(joinFlowProvider)
          .run(widget.payload, name: name, prompt: prompt);
      if (result case Err(:final error)) logWebAccessError(error);
      submission = joinSubmissionOf(result);
    } on Exception catch (exception) {
      // Váratlan platform- vagy fájlhiba: a képernyő ne ragadjon a
      // folyamatjelzőn, a beolvasó a hibapanelt mutatja.
      logWebAccessException(exception);
      if (mounted) Navigator.of(context).pop(const JoinFailed(SigningFailed()));
      return;
    }
    if (!mounted) return;
    switch (submission) {
      case JoinCanceled():
        setState(() => _isSending = false);
      case JoinSubmitted() || JoinFailed():
        Navigator.of(context).pop(submission);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // A `MaterialApp` regisztrálja a delegátorokat, ezért nem `null`.
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final isInvalid = _name.text.trim().isNotEmpty && !_isNameValid;
    return PopScope(
      canPop: !_isSending,
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.webJoinTitle, style: screenTitleStyle)),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              l10n.webJoinHeading,
              style: homeTitleStyle.copyWith(color: scheme.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              hostOfOrigin(widget.payload.origin),
              style: numeralMicroStyle.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 28),
            Text(
              l10n.webJoinNameLabel,
              style: sectionLabelStyle.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _name,
              autofocus: true,
              enabled: !_isSending,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.send,
              inputFormatters: [
                LengthLimitingTextInputFormatter(JoinRequestScreen.inputLimit),
              ],
              onChanged: (text) {
                widget.onNameChanged(text);
                setState(() {});
              },
              onSubmitted: (_) => unawaited(_submit()),
            ),
            if (isInvalid)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l10n.webJoinNameInvalid,
                  style: supportTextStyle.copyWith(color: scheme.error),
                ),
              ),
          ],
        ),
        bottomNavigationBar: WebBottomBar(
          children: [
            WebActionButton.primary(
              label: l10n.webJoinSubmit,
              isBusy: _isSending,
              onPressed: _isNameValid ? () => unawaited(_submit()) : null,
            ),
          ],
        ),
      ),
    );
  }
}
