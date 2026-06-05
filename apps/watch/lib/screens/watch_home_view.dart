import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watch/screens/race_shell.dart';
import 'package:watch/theme/watch_colors.dart';
import 'package:watch/watch_sync/watch_state_provider.dart';
import 'package:wear_plus/wear_plus.dart';

/// Az óra élő nézete: a telefon `WatchPayload`-jára vár, majd a két verseny-
/// nézetet (A↔B) jeleníti meg a [RaceShell]-ben. Payload előtt töltés-jelző,
/// hiba esetén „Nincs adat". Az ambient-módot a `wear_plus` `AmbientMode`
/// figyeli (vékony natív burok); a nézeteket a [RaceShell] rendereli
/// (ADR 0015/0016).
class WatchHomeView extends ConsumerWidget {
  /// Létrehozza a nézetet.
  const WatchHomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // A watchDarkTheme mindig regisztrálja a WatchColors-t, ezért a `!` itt
    // nem fut null-ra.
    final colors = Theme.of(context).extension<WatchColors>()!;
    final state = ref.watch(watchStateProvider);

    return Scaffold(
      body: SafeArea(
        child: state.when(
          loading: () =>
              Center(child: CircularProgressIndicator(color: colors.signal)),
          error: (_, _) => Center(
            child: Text('Nincs adat', style: TextStyle(color: colors.critical)),
          ),
          data: (payload) => AmbientMode(
            builder: (_, mode, _) => RaceShell(
              payload: payload,
              colors: colors,
              ambient: mode == WearMode.ambient,
            ),
          ),
        ),
      ),
    );
  }
}
