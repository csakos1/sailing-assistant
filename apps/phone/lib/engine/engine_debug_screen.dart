import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/engine/engine_heartbeat.dart';
import 'package:phone/providers/race_engine_host_provider.dart';

/// Debug-képernyő a háttér-engine (7-bg-b) on-device verifikációjához.
///
/// Indítja/leállítja a foreground service-t, és kiírja a legutóbb fogadott
/// életjelet. A zárolt képernyős bizonyíték az értesítés (a Pulzus-szám ott is
/// nő); ez a readout csak előtérben frissül, mert a UI-izolátum háttérben pauzál.
class EngineDebugScreen extends ConsumerStatefulWidget {
  /// Létrehozza a debug-képernyőt.
  const EngineDebugScreen({super.key});

  @override
  ConsumerState<EngineDebugScreen> createState() => _EngineDebugScreenState();
}

class _EngineDebugScreenState extends ConsumerState<EngineDebugScreen> {
  StreamSubscription<EngineHeartbeat>? _subscription;
  EngineHeartbeat? _lastHeartbeat;

  @override
  void initState() {
    super.initState();
    _subscription = ref.read(raceEngineHostProvider).heartbeats.listen((
      heartbeat,
    ) {
      if (mounted) {
        setState(() {
          _lastHeartbeat = heartbeat;
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
    final last = _lastHeartbeat;
    return Scaffold(
      appBar: AppBar(title: const Text('Engine debug (7-bg-b)')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              last == null
                  ? 'Nincs még életjel'
                  : 'Pulzus #${last.tickCount}\n'
                        '${last.timestamp.toIso8601String()}',
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
