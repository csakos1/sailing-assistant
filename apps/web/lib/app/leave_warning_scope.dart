import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foretack_web/app/leave_warning_provider.dart';

/// Amíg a fában van, a [shouldWarn] feltétel a fül bezárásakor
/// figyelmeztetést kérhet (ADR 0048 Addendum 4 K24).
///
/// A feltételt a bezárás pillanatában kérdezzük, a mindenkori
/// widgettől, ezért egy újraépítés utáni új függvény is számít.
class LeaveWarningScope extends ConsumerStatefulWidget {
  /// Hatókör a [shouldWarn] feltétellel a [child] körül.
  const LeaveWarningScope({
    required this.shouldWarn,
    required this.child,
    super.key,
  });

  /// Kell-e most figyelmeztetni (mentetlen változtatás, futó feltöltés).
  final bool Function() shouldWarn;

  /// A tartalom.
  final Widget child;

  @override
  ConsumerState<LeaveWarningScope> createState() => _LeaveWarningScopeState();
}

class _LeaveWarningScopeState extends ConsumerState<LeaveWarningScope> {
  late final VoidCallback _release;

  @override
  void initState() {
    super.initState();
    _release = ref.read(leaveWarningProvider).hold(_shouldWarn);
  }

  @override
  void dispose() {
    _release();
    super.dispose();
  }

  bool _shouldWarn() => widget.shouldWarn();

  @override
  Widget build(BuildContext context) => widget.child;
}
