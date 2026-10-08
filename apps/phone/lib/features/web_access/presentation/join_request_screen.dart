import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/features/web_access/application/join_submission.dart';
import 'package:phone/features/web_access/application/scan_problem.dart';
import 'package:phone/features/web_access/application/web_access_providers.dart';
import 'package:phone/features/web_access/data/web_account.dart';
import 'package:phone/features/web_access/presentation/web_access_prompts.dart';
import 'package:phone/features/web_access/presentation/widgets/web_bottom_bar.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:race_archive_api/race_archive_api.dart';

/// A csatlakozási kérelem űrlapja (ADR 0051 D3, makett 18e, Addendum 8 V9,
/// Addendum 9 X1, X2, X6).
///
/// Egy névmező és a „Kérelem küldése". A küldés a kulcsokat, az
/// ujjlenyomatot és a szerverhívást futtatja; az eredmény a beolvasóhoz
/// tér vissza (`JoinSubmitted` vagy `JoinFailed`). Egy elvetett
/// ujjlenyomat-ablak után a képernyő marad, a beírt névvel.
class JoinRequestScreen extends ConsumerStatefulWidget {
  /// Űrlap a [payload] belépési kéréshez; az [initialName] egy megőrzött
  /// név (X2).
  const JoinRequestScreen({
    required this.payload,
    this.initialName,
    super.key,
  });

  /// A beolvasott belépési QR.
  final LoginQrPayload payload;

  /// A mező kezdő szövege, ha van megőrzött név.
  final String? initialName;

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
    if (_isSending || !_isNameValid) return;
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
          .run(widget.payload, name: _name.text, prompt: prompt);
      submission = joinSubmissionOf(result);
    } on Exception {
      // Váratlan platform- vagy fájlhiba: a képernyő ne ragadjon a
      // folyamatjelzőn, a beolvasó a hibapanelt mutatja.
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
              onChanged: (_) => setState(() {}),
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
            FilledButton(
              onPressed: _isNameValid && !_isSending
                  ? () => unawaited(_submit())
                  : null,
              child: _isSending
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.webJoinSubmit),
            ),
          ],
        ),
      ),
    );
  }
}
