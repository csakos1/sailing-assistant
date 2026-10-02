import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foretack_web/race_log/log_view_mode.dart';

/// A napló választott nézete (ADR 0048 Addendum 4 K26).
///
/// Nem `autoDispose`: a munkameneten belül megmarad (G1), így törlés vagy
/// ÚJRA után a napló ugyanabban a nézetben nyílik.
final NotifierProvider<LogViewModeNotifier, LogViewMode> logViewModeProvider =
    NotifierProvider<LogViewModeNotifier, LogViewMode>(
      LogViewModeNotifier.new,
    );

/// A [logViewModeProvider] állapota.
class LogViewModeNotifier extends Notifier<LogViewMode> {
  @override
  LogViewMode build() => LogViewMode.list;

  /// A választott nézet; a setter párja (avoid_setters_without_getters).
  LogViewMode get mode => state;

  /// A nézet kiválasztása. Setter-forma, mert egyetlen tulajdonságot állít
  /// (use_setters_to_change_properties).
  set mode(LogViewMode mode) => state = mode;
}
