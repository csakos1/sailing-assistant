import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/features/web_access/application/join_outcome.dart';
import 'package:phone/features/web_access/application/web_access_providers.dart';
import 'package:phone/features/web_access/presentation/web_join_snack_bar.dart';

/// A függő csatlakozási kérelem csendes lekérdezése a főképernyőn (ADR
/// 0051 Addendum 9 X3).
///
/// Indításkor és minden előtérbe jövéskor egyszer kérdez, ha van élő
/// kérelem és a [child] útvonala van felül (a 18e-2 maga kérdez). A
/// döntést egy snackbar jelzi; a függő állapot és a hálózati hiba csendes
/// (H11). Versenyes providert nem érint (V10).
class PendingJoinWatcher extends ConsumerStatefulWidget {
  /// Figyelő a [child] fölött.
  const PendingJoinWatcher({required this.child, super.key});

  /// A főképernyő tartalma.
  final Widget child;

  @override
  ConsumerState<PendingJoinWatcher> createState() => _PendingJoinWatcherState();
}

class _PendingJoinWatcherState extends ConsumerState<PendingJoinWatcher>
    with WidgetsBindingObserver {
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
      ..addObserver(this)
      ..addPostFrameCallback((_) => unawaited(_check()));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_check());
  }

  Future<void> _check() async {
    if (_isChecking || !mounted) return;
    if (!(ModalRoute.isCurrentOf(context) ?? true)) return;
    _isChecking = true;
    try {
      final pending = await ref.read(pendingJoinProvider.future);
      if (pending == null || !mounted) return;
      final outcome = await ref.read(joinStatusCheckProvider).run(pending);
      if (!mounted) return;
      final isApproved = switch (outcome) {
        JoinApproved() => true,
        JoinNotApproved() => false,
        JoinStillPending() || JoinCheckFailed() => null,
      };
      if (isApproved == null) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(webJoinSnackBar(context, isApproved: isApproved));
    } on Exception catch (error) {
      // Egy olvashatatlan tár vagy platformhiba ne zavarja a főképernyőt;
      // a következő indítás újra próbálja.
      developer.log('Pending join check failed: $error', name: 'web_access');
    } finally {
      _isChecking = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
