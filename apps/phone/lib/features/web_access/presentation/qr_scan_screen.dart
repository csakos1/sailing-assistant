import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/features/web_access/application/join_submission.dart';
import 'package:phone/features/web_access/application/scan_problem.dart';
import 'package:phone/features/web_access/application/scan_route.dart';
import 'package:phone/features/web_access/application/web_access_error.dart';
import 'package:phone/features/web_access/application/web_access_providers.dart';
import 'package:phone/features/web_access/data/pending_join.dart';
import 'package:phone/features/web_access/data/web_account.dart';
import 'package:phone/features/web_access/presentation/join_pending_screen.dart';
import 'package:phone/features/web_access/presentation/join_request_screen.dart';
import 'package:phone/features/web_access/presentation/registration_done_screen.dart';
import 'package:phone/features/web_access/presentation/web_access_log.dart';
import 'package:phone/features/web_access/presentation/web_access_prompts.dart';
import 'package:phone/features/web_access/presentation/widgets/qr_camera_view.dart';
import 'package:phone/features/web_access/presentation/widgets/qr_finder.dart';
import 'package:phone/features/web_access/presentation/widgets/scan_problem_panel.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';

// A `paused` a fiók-csere dialógusa és a csatlakozási űrlap alatt: a
// kamera áll, de nincs folyamatjelző mögöttük.
enum _ScanPhase { scanning, paused, working, problem }

/// A webes QR-beolvasó (ADR 0051 D3–D4, makett 18b–18d, Addendum 8 V5).
///
/// A beolvasott kódot a `routeScan` dönti el; a képernyő csak végrehajtja:
/// belépés (sikerre a kérő böngésző adataival zár, a főképernyő
/// snackbart mutat), regisztráció (a 18f-re vált), csatlakozás (a 18e
/// űrlap fölötte nyílik, a beküldött kérelem a 18e-2-re vált), vagy
/// hibapanel. Egy elvetett ujjlenyomat-ablak után a belépésnél csendben
/// bezárul (H6), a csatlakozásnál az űrlap marad (Addendum 9 X2).
///
/// A csatlakozó neve a beolvasó állapota, ezért a beolvasó bezárásával
/// elvész (X2): a 18e-ről a kamerára visszalépve a következő beolvasás az
/// űrlapot ezzel tölti ki; egy elküldött, de el nem ment név után űrlap
/// nélkül az ujjlenyomat jön.
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

  // A 18e mezőjének utolsó szövege és az utoljára elküldött név (X2).
  String? _typedName;
  String? _sentName;

  Future<void> _onCode(String text) async {
    if (_phase != _ScanPhase.scanning) return;
    setState(() => _phase = _ScanPhase.working);
    unawaited(HapticFeedback.mediumImpact());
    try {
      final stored = await ref.read(webAccountProvider.future);
      if (!mounted) return;
      final livePending = await _livePendingJoin();
      if (!mounted) return;
      final route = routeScan(
        text,
        stored,
        pendingJoin: livePending,
        draftName: _sentName,
      );
      switch (route) {
        case ScanRejected(:final problem):
          _show(problem);
        case PendingJoinScan(:final pending):
          _openPending(pending);
        case JoinScan(:final payload, :final draftName):
          await _join(payload, draftName);
        case LoginScan(:final payload, :final account):
          await _signIn(payload, account);
        case EnrollScan(:final payload, :final replacing):
          // A regisztráció a csatlakozás megőrzött nevét is eldobja (X5).
          _forgetNames();
          await _enroll(payload, replacing);
      }
    } on Exception catch (exception) {
      // Váratlan platform- vagy fájlhiba (pl. a plugin csatornája): a
      // beolvasó ne ragadjon a folyamatjelzőn.
      logWebAccessException(exception);
      if (mounted) _show(const SigningFailed());
    }
  }

  Future<void> _signIn(LoginQrPayload payload, WebAccount account) async {
    final flow = ref.read(qrLoginFlowProvider);
    // A fiók a beolvasáskor megvolt; ha közben eltűnt, a telefon nem tud
    // aláírni, mint egy visszavont eszköz: a panel új csatlakozást kínál.
    if (flow == null) {
      _show(const DeviceRevokedProblem(isOwner: false));
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
      setState(() => _phase = _ScanPhase.paused);
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
        _fail(error, isOwner: true, kind: ScanKind.enrollment);
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

  // Az élő függő kérelem; a lejártat a kulcsaival együtt eldobja (X5).
  Future<PendingJoin?> _livePendingJoin() async {
    final pending = await ref.read(pendingJoinProvider.future);
    if (pending == null || !mounted) return null;
    final check = ref.read(joinStatusCheckProvider);
    if (!check.isExpired(pending)) return pending;
    await check.discard();
    return null;
  }

  // Csatlakozás: elküldött név nélkül az űrlap (a beírt szöveggel), vele
  // rögtön az ujjlenyomat (X2).
  Future<void> _join(LoginQrPayload payload, String? draftName) async {
    if (draftName == null) {
      await _openJoinForm(payload, initialName: _typedName);
      return;
    }
    final prompt = joinPromptText(
      // A `MaterialApp` regisztrálja a delegátorokat, ezért nem `null`.
      AppLocalizations.of(context)!,
      payload.origin,
    );
    final result = await ref
        .read(joinFlowProvider)
        .run(payload, name: draftName, prompt: prompt);
    if (result case Err(:final error)) logWebAccessError(error);
    if (!mounted) return;
    switch (joinSubmissionOf(result)) {
      case JoinSubmitted(:final pending):
        _openPending(pending);
      case JoinCanceled():
        // Az elvetett ujjlenyomat után a név az űrlapon javítható.
        await _openJoinForm(payload, initialName: draftName);
      case JoinFailed(:final problem):
        _show(problem);
    }
  }

  Future<void> _openJoinForm(
    LoginQrPayload payload, {
    String? initialName,
  }) async {
    setState(() => _phase = _ScanPhase.paused);
    final submission = await Navigator.of(context).push<JoinSubmission>(
      MaterialPageRoute<JoinSubmission>(
        builder: (_) => JoinRequestScreen(
          payload: payload,
          initialName: initialName,
          onNameChanged: (text) {
            _typedName = text;
            // Egy átírt név már nem az elküldött: a következő beolvasás az
            // űrlapot hozza, nem a régi névvel kér ujjlenyomatot.
            if (normalizeDisplayName(text) != _sentName) _sentName = null;
          },
          onNameSent: (name) {
            _sentName = name;
            _typedName = name;
          },
        ),
      ),
    );
    if (!mounted) return;
    switch (submission) {
      case JoinSubmitted(:final pending):
        _openPending(pending);
      case JoinFailed(:final problem):
        _show(problem);
      case JoinCanceled() || null:
        _resume();
    }
  }

  void _openPending(PendingJoin pending) {
    unawaited(
      Navigator.of(context).pushReplacement<void, BrowserLoginDetails>(
        MaterialPageRoute<void>(
          builder: (_) => JoinPendingScreen(pending: pending),
        ),
      ),
    );
  }

  void _forgetNames() {
    _typedName = null;
    _sentName = null;
  }

  void _fail(
    WebAccessError error, {
    required bool isOwner,
    ScanKind kind = ScanKind.login,
  }) {
    logWebAccessError(error);
    final problem = scanProblemOf(error, isOwner: isOwner, kind: kind);
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
