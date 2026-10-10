import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/providers/race_engine_lifecycle_provider.dart';

/// Az app előtér/háttér állapotát továbbítja az engine-életciklusnak
/// (ADR 0054 D4, E3): a gateway-próba csak előtérben fut, és előtte az
/// életciklus egyeztet a valóban futó háttér-service-szel.
///
/// A `resumed` előtér; a `hidden`, `paused` és `detached` háttér. Az
/// `inactive` (pl. lehúzott értesítési sáv, rendszer-dialógus) egyik sem,
/// így az nem indítja újra a próbát egy kézi leállítás után.
class AppForegroundBinding extends ConsumerStatefulWidget {
  /// A [child] köré tett figyelő.
  const AppForegroundBinding({required this.child, super.key});

  /// A becsomagolt fa.
  final Widget child;

  @override
  ConsumerState<AppForegroundBinding> createState() =>
      _AppForegroundBindingState();
}

class _AppForegroundBindingState extends ConsumerState<AppForegroundBinding> {
  late final AppLifecycleListener _listener;

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(onStateChange: _onStateChange);
    // Az induláskori állapotról nem jön esemény; ha már előtérben vagyunk,
    // az első képkocka után jelezzük (build közben providert nem írunk).
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _onStateChange(AppLifecycleState.resumed);
      });
    }
  }

  void _onStateChange(AppLifecycleState state) {
    final lifecycle = ref.read(raceEngineLifecycleProvider);
    if (state == AppLifecycleState.resumed) {
      unawaited(lifecycle.onAppResumed());
    } else if (state != AppLifecycleState.inactive) {
      lifecycle.onAppPaused();
    }
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
