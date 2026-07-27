import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watch/screens/watch_home_view.dart';
import 'package:watch/theme/night_mode_provider.dart';
import 'package:watch/theme/watch_theme.dart';

void main() {
  runApp(const ProviderScope(child: WatchApp()));
}

/// Az óra-alkalmazás gyökere: élő nézet, napszakhoz igazodó témával
/// (ADR 0015/0016, ADR 0039).
///
/// Napnyugta után az éjszakai (vörös-narancs) téma van érvényben, napkeltétől
/// a sötét. A váltást a `MaterialApp` `AnimatedTheme`-je vezeti át — napi
/// egyszer egy rövid átmenet kellemesebb, mint egy villanás (ADR 0039 D12).
class WatchApp extends ConsumerWidget {
  /// Létrehozza az app-gyökeret.
  const WatchApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isNight = ref.watch(nightModeProvider);

    return MaterialApp(
      title: 'Foretack',
      debugShowCheckedModeBanner: false,
      theme: isNight ? watchNightTheme : watchDarkTheme,
      home: const WatchHomeView(),
    );
  }
}
