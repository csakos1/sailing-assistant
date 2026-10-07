import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/features/web_access/application/scan_problem.dart';
import 'package:phone/features/web_access/application/scan_route.dart';
import 'package:phone/features/web_access/application/web_access_error.dart';
import 'package:phone/features/web_access/application/web_access_providers.dart';
import 'package:phone/features/web_access/data/web_account.dart';
import 'package:phone/features/web_access/presentation/registration_done_screen.dart';
import 'package:phone/features/web_access/presentation/web_access_prompts.dart';
import 'package:phone/features/web_access/presentation/widgets/qr_camera_view.dart';
import 'package:phone/features/web_access/presentation/widgets/qr_finder.dart';
import 'package:phone/features/web_access/presentation/widgets/scan_problem_panel.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';

// A `confirming` a fiók-csere dialógusa alatt: a kamera áll, de nincs
// folyamatjelző a dialógus mögött.
enum _ScanPhase { scanning, confirming, working, problem }

/// A webes QR-beolvasó (ADR 0051 D3–D4, makett 18b–18d, Addendum 8 V5).
///
/// A beolvasott kódot a `routeScan` dönti el; a képernyő csak végrehajtja:
/// belépés (sikerre a kérő böngésző adataival zár, a főképernyő
/// snackbart mutat), regisztráció (a 18f-re vált), vagy hibapanel. Egy
/// elvetett ujjlenyomat-ablak után csendben bezárul (H6).
class QrScanScreen extends ConsumerStatefulWidget {
  /// A beolvasó.
  const QrScanScreen({super.key});

  /// A beolvasó megnyitása; sikeres belépés után a kérő böngésző adataival
  /// tér vissza, különben `null`-lal.
  static Future<BrowserLoginDetails?> open(BuildContext context) =>
      Navigator.of(context).push(
        MaterialPageRoute<BrowserLoginDetails>(
          builder: (_) => const QrScanScreen(),
        ),
      );

  @override
  ConsumerState<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends ConsumerState<QrScanScreen> {
  _ScanPhase _phase = _ScanPhase.scanning;
  ScanProblem? _problem;

  Future<void> _onCode(String text) async {
    if (_phase != _ScanPhase.scanning) return;
    setState(() => _phase = _ScanPhase.working);
    unawaited(HapticFeedback.mediumImpact());
    try {
      final stored = await ref.read(webAccountProvider.future);
      if (!mounted) return;
      switch (routeScan(text, stored)) {
        case ScanRejected(:final problem):
          _show(problem);
        case JoinScan():
          _show(const NotRegistered());
        case LoginScan(:final payload, :final account):
          await _signIn(payload, account);
        case EnrollScan(:final payload, :final replacing):
          await _enroll(payload, replacing);
      }
    } on Exception {
      // Váratlan platform- vagy fájlhiba (pl. a plugin csatornája): a
      // beolvasó ne ragadjon a folyamatjelzőn.
      if (mounted) _show(const SigningFailed());
    }
  }

  Future<void> _signIn(LoginQrPayload payload, WebAccount account) async {
    final flow = ref.read(qrLoginFlowProvider);
    // A fiók a beolvasáskor megvolt; ha közben eltűnt, mintha nem lenne.
    if (flow == null) {
      _show(const NotRegistered());
      return;
    }
    // A `MaterialApp` regisztrálja a delegátorokat, ezért nem `null`.
    final l10n = AppLocalizations.of(context)!;
    final result = await flow.run(
      payload,
      promptOf: (details) => loginPromptText(l10n, details),
    );
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        Navigator.of(context).pop(value);
      case Err(:final error):
        _fail(error, isOwner: account.account.role == UserRole.owner);
    }
  }

  Future<void> _enroll(EnrollQrPayload payload, WebAccount? replacing) async {
    if (replacing != null) {
      setState(() => _phase = _ScanPhase.confirming);
      if (!await _confirmReplace(payload, replacing)) {
        _resume();
        return;
      }
      if (!mounted) return;
      setState(() => _phase = _ScanPhase.working);
    }
    // A lint az elágazáson át nem mindig követi a fenti ellenőrzést.
    if (!mounted) return;
    final prompt = enrollPromptText(
      // A `MaterialApp` regisztrálja a delegátorokat, ezért nem `null`.
      AppLocalizations.of(context)!,
      payload.origin,
    );
    final result = await ref
        .read(enrollmentFlowProvider)
        .run(payload, prompt: prompt);
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        unawaited(
          Navigator.of(context).pushReplacement<void, BrowserLoginDetails>(
            MaterialPageRoute<void>(
              builder: (_) => RegistrationDoneScreen(enrollment: value),
            ),
          ),
        );
      case Err(:final error):
        // Regisztrációs QR-t csak a tulajdonos kap (a CLI-ből, D3).
        _fail(error, isOwner: true, isEnrollment: true);
    }
  }

  Future<bool> _confirmReplace(
    EnrollQrPayload payload,
    WebAccount replacing,
  ) async {
    // A `MaterialApp` regisztrálja a delegátorokat, ezért nem `null`.
    final l10n = AppLocalizations.of(context)!;
    final isSameServer = replacing.origin == payload.origin;
    final isConfirmed = await showForetackDialog<bool>(
      context: context,
      title: l10n.webReplaceTitle,
      message: isSameServer
          ? l10n.webReplaceSameMessage
          : l10n.webReplaceForeignMessage(
              replacing.host,
              hostOfOrigin(payload.origin),
            ),
      actions: [
        ForetackDialogAction(label: l10n.webReplaceCancel, value: false),
        ForetackDialogAction(
          label: l10n.webReplaceConfirm,
          value: true,
          isDestructive: true,
        ),
      ],
    );
    return isConfirmed ?? false;
  }

  void _fail(
    WebAccessError error, {
    required bool isOwner,
    bool isEnrollment = false,
  }) {
    final problem = scanProblemOf(
      error,
      isOwner: isOwner,
      isEnrollment: isEnrollment,
    );
    if (problem == null) {
      Navigator.of(context).pop();
    } else {
      _show(problem);
    }
  }

  void _show(ScanProblem problem) => setState(() {
    _phase = _ScanPhase.problem;
    _problem = problem;
  });

  void _resume() {
    if (!mounted) return;
    setState(() {
      _phase = _ScanPhase.scanning;
      _problem = null;
    });
  }

  // „Csatlakozás kérése" (V9): a visszavont telefon helyi fiókja és kulcsai
  // törlődnek; a csatlakozáshoz egy friss belépési QR kell.
  Future<void> _requestJoin() async {
    await ref.read(webKeyOperationsProvider).deleteKeys();
    await ref.read(webAccountProvider.notifier).clear();
    _resume();
  }

  @override
  Widget build(BuildContext context) {
    // A `MaterialApp` regisztrálja a delegátorokat, ezért nem `null`.
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final camera = ref.watch(qrCameraBuilderProvider);
    final problem = _problem;
    return Scaffold(
      backgroundColor: scheme.surface,
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: Stack(
        fit: StackFit.expand,
        children: [
          camera(
            isActive: _phase == _ScanPhase.scanning,
            onCode: (text) => unawaited(_onCode(text)),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 18,
              children: [
                QrFinder(isDimmed: _phase == _ScanPhase.problem),
                SizedBox(
                  height: 20,
                  child: _phase == _ScanPhase.working
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          l10n.webScanHint,
                          style: supportTextStyle.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                ),
              ],
            ),
          ),
          if (problem != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: ScanProblemPanel(
                problem: problem,
                onRetry: _resume,
                onClose: () => Navigator.of(context).pop(),
                onRequestJoin: () => unawaited(_requestJoin()),
              ),
            ),
        ],
      ),
    );
  }
}
