import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/features/shell/shell_tab.dart';

/// A héj kiválasztott füle (ADR 0056 D2).
///
/// Provider, nem widget-állapot, mert kívülről is vált: rajtkor a
/// Műszerekre (`phone-ui-v1.md` §2), a vissza-gomb a Versenyekre.
final NotifierProvider<ShellTabNotifier, ShellTab> shellTabProvider =
    NotifierProvider<ShellTabNotifier, ShellTab>(ShellTabNotifier.new);

/// A [shellTabProvider] notifierje.
class ShellTabNotifier extends Notifier<ShellTab> {
  @override
  ShellTab build() => ShellTab.races;

  /// A kiválasztott fül.
  ShellTab get tab => state;

  /// Fül-váltás.
  set tab(ShellTab value) => state = value;
}
