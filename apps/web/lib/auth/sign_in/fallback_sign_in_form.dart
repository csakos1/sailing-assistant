import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:foretack_web/api/api_failure.dart';
import 'package:foretack_web/auth/auth_api_client_provider.dart';
import 'package:foretack_web/auth/sign_in/sign_in_link.dart';
import 'package:foretack_web/l10n/web_localizations.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';

/// A tartalék belépés űrlapja (17e, ADR 0051 Addendum 7 P5).
///
/// Egyetlen rejtett mező: jelszó vagy helyreállító kód, név nélkül. A
/// beírt szöveg csak az űrlap állapotában él; a visszalépéssel a widget
/// leszerelődik, és a szöveg vele vész.
///
/// A `WebLocalizations.of(context)!` és a `TextTones` biztonságos: a
/// `MaterialApp` és a `foretackTheme` regisztrálja őket.
class FallbackSignInForm extends ConsumerStatefulWidget {
  /// Űrlap; a sikeres belépést az [onSignedIn], a visszalépést az
  /// [onBack] kapja.
  const FallbackSignInForm({
    required this.onSignedIn,
    required this.onBack,
    super.key,
  });

  /// Az űrlap szélessége (17e).
  static const double width = 320;

  /// A mező és a gomb magassága (17e).
  static const double controlHeight = 48;

  /// A sikeres belépés a fiókkal.
  final void Function(AccountInfo account) onSignedIn;

  /// „Vissza a QR-kódhoz".
  final VoidCallback onBack;

  @override
  ConsumerState<FallbackSignInForm> createState() => _FallbackSignInFormState();
}

/// A legutóbbi próbálkozás kudarca.
enum _Problem { none, rejected, unreachable }

class _FallbackSignInFormState extends ConsumerState<FallbackSignInForm> {
  final TextEditingController _secret = TextEditingController();
  final FocusNode _focus = FocusNode();
  bool _isSubmitting = false;
  _Problem _problem = _Problem.none;
  int _lockSecondsLeft = 0;
  Timer? _lockTimer;

  bool get _isLocked => _lockSecondsLeft > 0;

  @override
  void dispose() {
    _lockTimer?.cancel();
    _secret.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final secret = _secret.text;
    if (secret.isEmpty || _isSubmitting || _isLocked) return;
    setState(() => _isSubmitting = true);
    final result = await ref
        .read(authApiClientProvider)
        .signInWithSecret(secret);
    if (!mounted) return;
    switch (result) {
      case Ok(value: final account):
        widget.onSignedIn(account);
      case Err(
        error: ServerFailure(error: TooManyAttempts(:final retryAfterSeconds)),
      ):
        _lock(retryAfterSeconds);
      case Err(error: ServerFailure(error: NotAuthenticated())):
        // Egy semleges mondat: nem árulja el, jelszó vagy kód volt-e
        // rossz (17e-2). A mező kiürül, a fókusz marad.
        _secret.clear();
        setState(() {
          _isSubmitting = false;
          _problem = _Problem.rejected;
        });
        _focus.requestFocus();
      case Err():
        setState(() {
          _isSubmitting = false;
          _problem = _Problem.unreachable;
        });
    }
  }

  // 17e-3: a várakozás a `Retry-After` szerint; a kijelzés percre felfelé
  // kerekít, a feloldás másodpercre pontos.
  void _lock(int retryAfterSeconds) {
    _secret.clear();
    _lockTimer?.cancel();
    setState(() {
      _isSubmitting = false;
      _problem = _Problem.none;
      _lockSecondsLeft = retryAfterSeconds < 1 ? 1 : retryAfterSeconds;
    });
    _lockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _lockSecondsLeft--);
      if (_lockSecondsLeft > 0) return;
      timer.cancel();
      // A mező csak a következő képkockán engedélyezett; egy tiltott mezőn
      // a fókusz-kérés elveszne.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focus.requestFocus();
      });
    });
  }

  void _clearProblem(String _) {
    if (_problem == _Problem.none) return;
    setState(() => _problem = _Problem.none);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = WebLocalizations.of(context)!;
    final low = Theme.of(context).extension<TextTones>()!.low;
    final message = _messageLine(l10n);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: FallbackSignInForm.width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 10,
            children: [
              Text(
                l10n.signInFallbackLabelCaps,
                style: sectionLabelStyle.copyWith(color: low),
              ),
              Opacity(opacity: _isLocked ? 0.35 : 1, child: _field(context)),
              ?message,
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Opacity(
                  opacity: _isLocked ? 0.35 : 1,
                  child: _submitButton(context, l10n),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 44),
        SignInLink(label: l10n.signInBackToQr, onPressed: widget.onBack),
      ],
    );
  }

  Widget _field(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isRejected = _problem == _Problem.rejected;
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: color, width: width),
    );
    return TextField(
      controller: _secret,
      focusNode: _focus,
      autofocus: true,
      enabled: !_isLocked,
      obscureText: true,
      autocorrect: false,
      enableSuggestions: false,
      autofillHints: const [AutofillHints.password],
      keyboardType: TextInputType.visiblePassword,
      textInputAction: TextInputAction.done,
      // Egy jelszó-kezelő által kitöltött hosszabb kód se vágódjon el;
      // a szerver a 128 kódpont fölöttit amúgy is elutasítja.
      inputFormatters: [LengthLimitingTextInputFormatter(256)],
      onChanged: _clearProblem,
      onSubmitted: (_) => unawaited(_submit()),
      style: numeralMicroStyle.copyWith(
        color: scheme.onSurface,
        letterSpacing: 2.8,
      ),
      cursorColor: scheme.onSurface,
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: scheme.surfaceContainerHigh,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
        // A hibás próba piros kerete az egyetlen piros (17e-2).
        enabledBorder: border(isRejected ? scheme.error : scheme.outline, 1),
        focusedBorder: isRejected
            ? border(scheme.error, 1)
            : border(scheme.primary, 2),
        disabledBorder: border(scheme.outline, 1),
      ),
    );
  }

  Widget _submitButton(BuildContext context, WebLocalizations l10n) {
    final scheme = Theme.of(context).colorScheme;
    final canSubmit = !_isSubmitting && !_isLocked;
    return SizedBox(
      height: FallbackSignInForm.controlHeight,
      child: FilledButton(
        onPressed: canSubmit ? () => unawaited(_submit()) : null,
        style: FilledButton.styleFrom(
          shape: const RoundedRectangleBorder(),
          // Tiltva is a teal gomb látszik, a 35% a tiltást jelzi (17e-3).
          disabledBackgroundColor: scheme.primary,
          disabledForegroundColor: scheme.onPrimary,
          textStyle: supportTextStyle.copyWith(fontWeight: FontWeight.w600),
        ),
        child: Text(l10n.signInSubmit),
      ),
    );
  }

  Widget? _messageLine(WebLocalizations l10n) {
    if (_isLocked) {
      final minutes = (_lockSecondsLeft + 59) ~/ 60;
      return _ProblemLine(
        text: _withMonoNumber(l10n.signInRetryInMinutes(minutes), minutes),
      );
    }
    return switch (_problem) {
      _Problem.none => null,
      _Problem.rejected => _ProblemLine(
        text: TextSpan(text: l10n.signInRejected),
      ),
      _Problem.unreachable => _ProblemLine(
        text: TextSpan(text: l10n.signInOffline),
      ),
    };
  }
}

/// A [sentence] a benne álló [number] számmal mono betűvel (17e-3).
///
/// A mondat egy fordítható egész (a szórend nyelvenként más); a számot a
/// kész szövegben keresi meg.
TextSpan _withMonoNumber(String sentence, int number) {
  final digits = '$number';
  final at = sentence.indexOf(digits);
  if (at < 0) return TextSpan(text: sentence);
  return TextSpan(
    children: [
      TextSpan(text: sentence.substring(0, at)),
      TextSpan(
        text: digits,
        style: const TextStyle(fontFamily: numeralFontFamily),
      ),
      TextSpan(text: sentence.substring(at + digits.length)),
    ],
  );
}

/// A hibasor: 8 px-es piros négyzet és a mondat (17e-2, 17e-3).
class _ProblemLine extends StatelessWidget {
  const _ProblemLine({required this.text});

  final TextSpan text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      spacing: 8,
      children: [
        SizedBox.square(
          dimension: 8,
          child: ColoredBox(color: scheme.error),
        ),
        Flexible(
          child: Text.rich(
            text,
            style: supportTextStyle.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}
