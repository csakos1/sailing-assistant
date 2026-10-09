import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:foretack_web/auth/auth_api_client_provider.dart';
import 'package:foretack_web/auth/sign_in/countdown_bar.dart';
import 'package:foretack_web/auth/sign_in/qr_code_image.dart';
import 'package:foretack_web/auth/sign_in/qr_reveal.dart';
import 'package:foretack_web/auth/sign_in/qr_sign_in_controller.dart';
import 'package:foretack_web/auth/sign_in/sign_in_link.dart';
import 'package:foretack_web/auth/sign_in/sign_in_status_box.dart';
import 'package:foretack_web/l10n/web_localizations.dart';
import 'package:race_archive_api/race_archive_api.dart';

/// A QR-belépés (17a–17d, ADR 0051 Addendum 7 P4).
///
/// A kérést és a lekérdezést a [QrSignInController] vezeti; a panel csak
/// a szakaszát rajzolja. A panel élete a lekérdezés élete: a tartalék
/// űrlapra váltva vagy belépés után leszerelődik, és minden időzítője
/// leáll.
///
/// A `WebLocalizations.of(context)!` és a `TextTones` biztonságos: a
/// `MaterialApp` és a `foretackTheme` regisztrálja őket.
class QrSignInPanel extends ConsumerStatefulWidget {
  /// Panel; a sikeres belépést az [onSignedIn], a tartalék linket az
  /// [onUseFallback] kapja.
  const QrSignInPanel({
    required this.onSignedIn,
    required this.onUseFallback,
    super.key,
  });

  /// A sikeres belépés a fiókkal.
  final void Function(AccountInfo account) onSignedIn;

  /// „Belépés jelszóval vagy helyreállító kóddal".
  final VoidCallback onUseFallback;

  @override
  ConsumerState<QrSignInPanel> createState() => _QrSignInPanelState();
}

class _QrSignInPanelState extends ConsumerState<QrSignInPanel> {
  late final QrSignInController _controller = QrSignInController(
    client: ref.read(authApiClientProvider),
    onSignedIn: (account) => widget.onSignedIn(account),
  );

  @override
  void initState() {
    super.initState();
    _controller.start();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _controller,
    builder: (context, _) {
      final l10n = WebLocalizations.of(context)!;
      final isAwaiting =
          _controller.phase == QrSignInPhase.awaitingPhone ||
          _controller.phase == QrSignInPhase.awaitingOwner;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _phaseView(context, l10n),
          const SizedBox(height: 44),
          if (isAwaiting)
            SignInLink(
              label: l10n.signInBackToQr,
              onPressed: _controller.restart,
            )
          else
            SignInLink(
              label: l10n.signInUseFallback,
              onPressed: widget.onUseFallback,
            ),
        ],
      );
    },
  );

  Widget _phaseView(BuildContext context, WebLocalizations l10n) {
    final scheme = Theme.of(context).colorScheme;
    final qrText = _controller.qrText;
    return switch (_controller.phase) {
      QrSignInPhase.starting => const SizedBox.square(
        dimension: QrCodeImage.extent,
        child: Center(child: CircularProgressIndicator()),
      ),
      QrSignInPhase.unavailable => SignInStatusBox(
        children: [_ConnectionLine(text: l10n.signInOffline)],
      ),
      QrSignInPhase.showing when qrText != null => _QrWithCaption(
        qrText: qrText,
        secondsLeft: _controller.secondsLeft,
        caption: _caption(context, l10n),
      ),
      // A `showing` mindig QR-szöveggel jár; e nélkül csak várni lehet.
      QrSignInPhase.showing => const SizedBox.square(
        dimension: QrCodeImage.extent,
      ),
      QrSignInPhase.awaitingPhone => _AwaitingColumn(
        isOffline: _controller.isOffline,
        box: SignInStatusBox(
          footer: const _ActivityMark(),
          children: [
            Icon(
              Icons.fingerprint,
              size: 44,
              color: scheme.onSecondaryContainer,
            ),
            Text(
              l10n.signInConfirmOnPhone,
              style: listItemTitleStyle,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      QrSignInPhase.awaitingOwner => _AwaitingColumn(
        isOffline: _controller.isOffline,
        box: SignInStatusBox(
          children: [
            Text(
              l10n.signInJoinSentCaps,
              style: sectionLabelStyle.copyWith(
                color: Theme.of(context).extension<TextTones>()!.low,
              ),
            ),
            Text(
              l10n.signInJoinAwaitingOwner,
              style: listItemTitleStyle,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        countdown: CountdownBar(
          secondsLeft: _controller.secondsLeft,
          totalSeconds: QrSignInController.joinSeconds,
        ),
      ),
    };
  }

  // A QR alatti felirat: a kapcsolat hiánya, a lejárt kérés (17d-2), vagy
  // az alap felszólítás.
  Widget _caption(BuildContext context, WebLocalizations l10n) {
    final scheme = Theme.of(context).colorScheme;
    if (_controller.isOffline) {
      return _ConnectionLine(text: l10n.signInOffline);
    }
    if (_controller.showsExpiredNotice) {
      return Text(
        l10n.signInQrExpired,
        style: supportTextStyle.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      );
    }
    return Text(
      l10n.signInScanPrompt,
      style: supportTextStyle.copyWith(color: scheme.onSurfaceVariant),
    );
  }
}

/// A QR, alatta a felirat és a 60 mp-es visszaszámláló (17a, 17b, 17d-2).
class _QrWithCaption extends StatelessWidget {
  const _QrWithCaption({
    required this.qrText,
    required this.secondsLeft,
    required this.caption,
  });

  final String qrText;
  final int secondsLeft;
  final Widget caption;

  @override
  Widget build(BuildContext context) {
    final label = WebLocalizations.of(context)!.signInQrLabel;
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 16,
      children: [
        QrReveal(
          qrText: qrText,
          builder: (text) => QrCodeImage(text: text, semanticLabel: label),
        ),
        caption,
        CountdownBar(
          secondsLeft: secondsLeft,
          totalSeconds: QrSignInController.qrSeconds,
        ),
      ],
    );
  }
}

/// Az állapotdoboz, alatta a visszaszámláló (17d-1) és a kapcsolat
/// hiánya, ha van.
class _AwaitingColumn extends StatelessWidget {
  const _AwaitingColumn({
    required this.box,
    required this.isOffline,
    this.countdown,
  });

  final Widget box;
  final bool isOffline;
  final Widget? countdown;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    spacing: 16,
    children: [
      box,
      ?countdown,
      if (isOffline)
        _ConnectionLine(text: WebLocalizations.of(context)!.signInOffline),
    ],
  );
}

/// „Nincs kapcsolat a szerverrel" (P4), halkan.
class _ConnectionLine extends StatelessWidget {
  const _ConnectionLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: supportTextStyle.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
    textAlign: TextAlign.center,
  );
}

/// A 17c dobozának alsó élén álló 2 px-es teal jel: a böngésző figyel.
class _ActivityMark extends StatelessWidget {
  const _ActivityMark();

  @override
  Widget build(BuildContext context) => Align(
    child: FractionallySizedBox(
      widthFactor: 0.38,
      child: SizedBox(
        height: 2,
        child: ColoredBox(color: Theme.of(context).colorScheme.primary),
      ),
    ),
  );
}
