import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/features/web_access/application/scan_problem.dart';
import 'package:phone/l10n/app_localizations.dart';

/// A beolvasó alsó hibapanelje (ADR 0051 Addendum 1 H7, makett
/// 18d-2…5, Addendum 8 V6).
///
/// Piros négyzet + cím, egy magyarázó sor, és két gomb: az elsődleges
/// („Újra", a legénység visszavont telefonján „Csatlakozás kérése") és a
/// „Bezárás". A tulajdonos visszavont telefonján csak a „Bezárás" marad:
/// neki a CLI-s újraregisztráció az út (H7).
class ScanProblemPanel extends StatelessWidget {
  /// Panel a [problem]-hez.
  const ScanProblemPanel({
    required this.problem,
    required this.onRetry,
    required this.onClose,
    required this.onRequestJoin,
    super.key,
  });

  /// A mutatott hiba.
  final ScanProblem problem;

  /// „Újra": a kamera újraindul.
  final VoidCallback onRetry;

  /// „Bezárás": a beolvasó bezárul.
  final VoidCallback onClose;

  /// „Csatlakozás kérése": a helyi fiók és a kulcsok törlése, újra
  /// beolvasás (V9).
  final VoidCallback onRequestJoin;

  @override
  Widget build(BuildContext context) {
    // A `MaterialApp` regisztrálja a delegátorokat, ezért nem `null`.
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final text = _textOf(problem, l10n);
    final primary = switch (problem) {
      DeviceRevokedProblem(isOwner: true) => null,
      DeviceRevokedProblem() => (l10n.webScanRequestJoin, onRequestJoin),
      _ => (l10n.webScanRetry, onRetry),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                spacing: 10,
                children: [
                  SizedBox.square(
                    dimension: 8,
                    child: ColoredBox(color: scheme.error),
                  ),
                  Expanded(
                    child: Text(
                      text.title,
                      style: listItemTitleStyle.copyWith(
                        fontSize: 16,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _Message(message: text.message, mono: text.mono),
              const SizedBox(height: 16),
              Row(
                spacing: 8,
                children: [
                  if (primary != null)
                    Expanded(
                      child: FilledButton(
                        onPressed: primary.$2,
                        child: Text(primary.$1),
                      ),
                    ),
                  if (primary == null) const Spacer(),
                  OutlinedButton(
                    onPressed: onClose,
                    child: Text(l10n.webScanClose),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.message, required this.mono});

  final String message;
  final String? mono;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = supportTextStyle.copyWith(color: scheme.onSurfaceVariant);
    final monoText = mono;
    if (monoText == null) return Text(message, style: style);
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(text: '$message '),
          TextSpan(
            text: monoText,
            style: numeralMicroStyle.copyWith(color: scheme.onSurface),
          ),
        ],
      ),
    );
  }
}

typedef _PanelText = ({String title, String message, String? mono});

_PanelText _textOf(ScanProblem problem, AppLocalizations l10n) =>
    switch (problem) {
      NotForetackCode() => (
        title: l10n.webScanNotForetackTitle,
        message: l10n.webScanNotForetackMessage,
        mono: null,
      ),
      UnsupportedCode() => (
        title: l10n.webScanUnsupportedTitle,
        message: l10n.webScanUnsupportedMessage,
        mono: null,
      ),
      ExpiredCode(:final kind) => (
        title: l10n.webScanExpiredTitle,
        message: switch (kind) {
          ScanKind.login => l10n.webScanExpiredMessage,
          ScanKind.enrollment => l10n.webScanExpiredEnrollMessage,
          ScanKind.join => l10n.webScanExpiredJoinMessage,
        },
        mono: null,
      ),
      ForeignServer(:final host) => (
        title: l10n.webScanForeignTitle,
        message: l10n.webScanForeignMessage,
        mono: host,
      ),
      NoConnection() => (
        title: l10n.webScanNoConnectionTitle,
        message: l10n.webScanNoConnectionMessage,
        mono: null,
      ),
      TooManyAttemptsProblem(:final minutes) => (
        title: l10n.webScanTooManyTitle,
        message: l10n.webScanTooManyMessage(minutes),
        mono: null,
      ),
      DeviceRevokedProblem(:final isOwner) => (
        title: l10n.webScanRevokedTitle,
        message: isOwner
            ? l10n.webScanRevokedOwnerMessage
            : l10n.webScanRevokedCrewMessage,
        mono: null,
      ),
      BiometricsUnavailable() => (
        title: l10n.webScanBiometricsUnavailableTitle,
        message: l10n.webScanBiometricsUnavailableMessage,
        mono: null,
      ),
      BiometricsLockedOut() => (
        title: l10n.webScanLockedOutTitle,
        message: l10n.webScanLockedOutMessage,
        mono: null,
      ),
      SigningFailed() => (
        title: l10n.webScanSigningFailedTitle,
        message: l10n.webScanSigningFailedMessage,
        mono: null,
      ),
    };
