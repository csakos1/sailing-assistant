import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/features/web_access/application/join_outcome.dart';
import 'package:phone/features/web_access/application/web_access_providers.dart';
import 'package:phone/features/web_access/data/web_account.dart';
import 'package:phone/features/web_access/presentation/web_join_snack_bar.dart';

/// A főképernyő webes állapotának csendes frissítése (ADR 0051 Addendum 9
/// X3, Addendum 10 Z5).
///
/// Indításkor és minden előtérbe jövéskor egyszer fut, ha a [child]
/// útvonala van felül: függő csatlakozási kérelemnél azt kérdezi le (a
/// döntést snackbar jelzi), fióknál a szalagot és a `/me`-t. Egy új fiók
/// (regisztráció, jóváhagyott csatlakozás) után is frissít. A függő
/// állapot és a hálózati hiba csendes (H11). Versenyes providert nem
/// érint (V10).
class WebAccessRefresher extends ConsumerStatefulWidget {
  /// Frissítő a [child] fölött.
  const WebAccessRefresher({required this.child, super.key});

  /// A főképernyő tartalma.
  final Widget child;

  @override
  ConsumerState<WebAccessRefresher> createState() => _WebAccessRefresherState();
}

class _WebAccessRefresherState extends ConsumerState<WebAccessRefresher>
    with WidgetsBindingObserver {
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
      ..addObserver(this)
      ..addPostFrameCallback((_) => unawaited(_refresh()));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_refresh());
  }

  Future<void> _refresh() async {
    if (_isRefreshing || !mounted) return;
    if (!(ModalRoute.isCurrentOf(context) ?? true)) return;
    _isRefreshing = true;
    try {
      final pending = await ref.read(pendingJoinProvider.future);
      if (!mounted) return;
      if (pending == null) {
        await ref.read(webAccessStatusProvider.notifier).refresh();
        return;
      }
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
      developer.log('Web access refresh failed: $error', name: 'web_access');
    } finally {
      _isRefreshing = false;
    }
  }

  // Egy új fiók (regisztráció, jóváhagyott csatlakozás, csere) után a
  // szalag azonnal frissül; az állapot maga a fiókváltáskor üres lesz.
  void _onAccountChanged(
    AsyncValue<WebAccount?>? previous,
    AsyncValue<WebAccount?> next,
  ) {
    final before = previous?.valueOrNull;
    final after = next.valueOrNull;
    if (after == null) return;
    if (before?.origin == after.origin && before?.deviceId == after.deviceId) {
      return;
    }
    unawaited(_refreshStatus());
  }

  Future<void> _refreshStatus() async {
    try {
      await ref.read(webAccessStatusProvider.notifier).refresh();
    } on Exception catch (error) {
      // Egy tár- vagy platformhiba a fiók mentésekor ne zavarja a
      // főképernyőt; a következő előtérbe jövés újra próbálja.
      developer.log('Web access refresh failed: $error', name: 'web_access');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(webAccountProvider, _onAccountChanged);
    return widget.child;
  }
}
