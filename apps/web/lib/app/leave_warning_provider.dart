import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foretack_web/app/leave_warning_registry.dart';
import 'package:foretack_web/app/platform/leave_warning_binding.dart';

/// A fül bezárására figyelmeztető feltételek (ADR 0048 Addendum 4 K24),
/// a böngésző `beforeunload` eseményéhez kötve. Az első olvasáskor köt,
/// és a provider eldobásakor leválaszt.
final Provider<LeaveWarningRegistry> leaveWarningProvider =
    Provider<LeaveWarningRegistry>((ref) {
      final registry = LeaveWarningRegistry();
      ref.onDispose(bindLeaveWarning(registry));
      return registry;
    });
