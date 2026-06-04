import 'dart:async';

import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/providers/race_engine_host_provider.dart';

/// Debug-képernyő a háttér-engine on-device verifikációjához.
///
/// Indítja/leállítja a foreground service-t, és kiírja a legutóbb fogadott
/// snapshot esemény-számát. A zárolt képernyős bizonyíték az értesítés (a szám
/// ott is nő); ez a readout csak előtérben frissül, mert a UI-izolátum háttérben
/// pauzál.
class EngineDebugScreen extends ConsumerStatefulWidget {
  /// Létrehozza a debug-képernyőt.
  const EngineDebugScreen({super.key});

  @override
  ConsumerState<EngineDebugScreen> createState() => _EngineDebugScreenState();
}

class _EngineDebugScreenState extends ConsumerState<EngineDebugScreen> {
  StreamSubscription<RaceSnapshot>? _subscription;
  RaceSnapshot? _lastSnapshot;

  @override
  void initState() {
    super.initState();
    _subscription = ref.read(raceEngineHostProvider).snapshots.listen((
      snapshot,
    ) {
      if (mounted) {
        setState(() {
          _lastSnapshot = snapshot;
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final host = ref.watch(raceEngineHostProvider);
    final last = _lastSnapshot;
    return Scaffold(
      appBar: AppBar(title: const Text('Engine debug')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              last == null
                  ? 'Nincs még snapshot'
                  : 'Események #${last.eventCount}\n'
                        '${last.tickTime.toIso8601String()}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              children: [
                ElevatedButton(
                  onPressed: () => unawaited(host.start()),
                  child: const Text('Engine indítása'),
                ),
                OutlinedButton(
                  onPressed: () => unawaited(host.stop()),
                  child: const Text('Engine leállítása'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
