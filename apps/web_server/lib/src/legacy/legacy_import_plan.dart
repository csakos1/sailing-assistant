import 'package:equatable/equatable.dart';
import 'package:web_server/src/legacy/legacy_plan_item.dart';
import 'package:web_server/src/legacy/telemetry_candidate.dart';

/// Az Excel-import terve: a próbafuttatás ezt írja ki, az `--apply` ezt
/// hajtja végre (ADR 0048 D7, Addendum 6 M1).
final class LegacyImportPlan extends Equatable {
  /// Terv a [items] tételekkel.
  const LegacyImportPlan({
    required this.items,
    required this.telemetryOnly,
    required this.matchProblems,
  });

  /// A tételek az Excel sorrendjében.
  final List<LegacyPlanItem> items;

  /// A telemetriás versenyek, amelyekhez egy sor sem került.
  final List<TelemetryCandidate> telemetryOnly;

  /// A `--match` kapcsolók hibái. Ha van ilyen, az `--apply` nem fut.
  final List<String> matchProblems;

  @override
  List<Object?> get props => [items, telemetryOnly, matchProblems];
}
