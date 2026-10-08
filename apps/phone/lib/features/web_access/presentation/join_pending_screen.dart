import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/features/web_access/application/join_outcome.dart';
import 'package:phone/features/web_access/application/web_access_providers.dart';
import 'package:phone/features/web_access/data/pending_join.dart';
import 'package:phone/features/web_access/presentation/join_formatters.dart';
import 'package:phone/features/web_access/presentation/web_join_snack_bar.dart';
import 'package:phone/features/web_access/presentation/widgets/web_bottom_bar.dart';
import 'package:phone/features/web_access/presentation/widgets/web_detail_row.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:phone/providers/clock_provider.dart';

/// A beküldött csatlakozási kérelem (ADR 0051 D3, makett 18e-2, Addendum 8
/// V9, Addendum 9 X3, X6).
///
/// Amíg nyitva és előtérben van, [pollInterval]-onként lekérdezi a
/// kérelmet; háttérben szünetel (akkumulátor), előtérbe jövéskor rögtön
/// kérdez. Jóváhagyáskor bezárul, és a főképernyő snackbart mutat;
/// elutasításkor vagy lejáratkor a képernyő ezt jelzi. A „Bezárás" csak
/// bezár: a kérelem él tovább, és a főképernyő indításkor kérdezi le.
class JoinPendingScreen extends ConsumerStatefulWidget {
  /// A [pending] kérelem képernyője.
  const JoinPendingScreen({required this.pending, super.key});

  /// A lekérdezés üteme (V9).
  static const Duration pollInterval = Duration(seconds: 5);

  /// A függő kérelem.
  final PendingJoin pending;

  @override
  ConsumerState<JoinPendingScreen> createState() => _JoinPendingScreenState();
}

class _JoinPendingScreenState extends ConsumerState<JoinPendingScreen>
    with WidgetsBindingObserver {
  Timer? _timer;
  bool _isChecking = false;
  bool _isNotApproved = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startPolling();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (_timer == null && !_isNotApproved) _startPolling();
      case AppLifecycleState.paused || AppLifecycleState.detached:
        _stopPolling();
      case AppLifecycleState.inactive || AppLifecycleState.hidden:
        break;
    }
  }

  // Egy már korábban beküldött kérelemnél ne kelljen 5 mp-et várni.
  void _startPolling() {
    _timer = Timer.periodic(
      JoinPendingScreen.pollInterval,
      (_) => unawaited(_check()),
    );
    unawaited(_check());
  }

  void _stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _check() async {
    if (_isChecking || _isNotApproved) return;
    _isChecking = true;
    final JoinOutcome outcome;
    try {
      outcome = await ref.read(joinStatusCheckProvider).run(widget.pending);
    } on Exception catch (error) {
      // Egy tár- vagy platformhiba ne állítsa le a lekérdezést: a következő
      // ütem újra próbálja.
      developer.log('Pending join check failed: $error', name: 'web_access');
      return;
    } finally {
      _isChecking = false;
    }
    if (!mounted) return;
    switch (outcome) {
      case JoinApproved():
        _stopPolling();
        // A messenger a pop előtt kell: utána ez a `context` már nem él.
        final messenger = ScaffoldMessenger.of(context);
        final snackBar = webJoinSnackBar(context, isApproved: true);
        Navigator.of(context).pop();
        messenger.showSnackBar(snackBar);
      case JoinNotApproved():
        _stopPolling();
        setState(() => _isNotApproved = true);
      case JoinStillPending() || JoinCheckFailed():
        // A hátralévő idő sora frissül.
        setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // A `MaterialApp` regisztrálja a delegátorokat, ezért nem `null`.
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final pending = widget.pending;
    final identity = ref.watch(deviceIdentityProvider).valueOrNull;
    final left = joinTimeLeft(pending.expiresAt, ref.watch(clockProvider)());
    return Scaffold(
      appBar: AppBar(title: Text(l10n.webJoinTitle, style: screenTitleStyle)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: _isNotApproved
            ? [
                _StatusLine(
                  color: scheme.error,
                  text: l10n.webJoinNotApproved,
                  style: supportTextStyle.copyWith(color: scheme.onSurface),
                ),
              ]
            : [
                _StatusLine(
                  color: scheme.primary,
                  text: l10n.webJoinSentLabel,
                  style: sectionLabelStyle.copyWith(color: scheme.primary),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.webJoinWaiting,
                  style: homeTitleStyle.copyWith(color: scheme.onSurface),
                ),
                const SizedBox(height: 20),
                WebDetailRow(label: l10n.webJoinName, value: pending.name),
                WebDetailRow(
                  label: l10n.webJoinPhone,
                  value: identity?.deviceName ?? missingValueLabel,
                ),
                WebDetailRow(
                  label: l10n.webJoinSentAt,
                  value: formatLocalClock(
                    pending.expiresAt.subtract(joinRequestValidity),
                  ),
                ),
                WebDetailRow(
                  label: l10n.webJoinExpiresIn,
                  value: l10n.webJoinRemaining(left.hours, left.minutes),
                ),
              ],
      ),
      bottomNavigationBar: WebBottomBar(
        children: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.webScanClose),
          ),
        ],
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({
    required this.color,
    required this.text,
    required this.style,
  });

  final Color color;
  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => Row(
    spacing: 8,
    children: [
      SizedBox.square(dimension: 8, child: ColoredBox(color: color)),
      Expanded(child: Text(text, style: style)),
    ],
  );
}
