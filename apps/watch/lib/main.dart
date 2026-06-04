import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watch/screens/watch_home_view.dart';
import 'package:watch/theme/watch_theme.dart';

void main() {
  runApp(const ProviderScope(child: WatchApp()));
}

/// Az óra-alkalmazás gyökere: sötét téma + élő nézet (ADR 0015/0016).
class WatchApp extends StatelessWidget {
  /// Létrehozza az app-gyökeret.
  const WatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Foretack',
      debugShowCheckedModeBanner: false,
      theme: watchDarkTheme,
      home: const WatchHomeView(),
    );
  }
}
