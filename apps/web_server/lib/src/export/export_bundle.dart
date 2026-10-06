import 'dart:async';
import 'dart:io';

/// Egy kész export: a tar.gz fájl, a letöltési név és a takarítás (ADR
/// 0050 Addendum 3 G2).
final class ExportBundle {
  /// Csomag a [file]-lal; a [release] a streamelés után takarít és
  /// felszabadítja az exportot.
  ExportBundle({
    required this.fileName,
    required this.length,
    required File file,
    required Future<void> Function() release,
  }) : _file = file,
       _release = release;

  /// A letöltött fájl neve (`foretack-history-<YYYY-MM-DD>.tar.gz`).
  final String fileName;

  /// A fájl hossza bájtban (`Content-Length`).
  final int length;

  final File _file;
  final Future<void> Function() _release;
  Future<void>? _releasing;

  /// A fájl tartalma; egyszer olvasható.
  ///
  /// A stream végén, olvasási hibánál és a lemondásnál (a kapcsolat
  /// megszakadása) is takarít, akkor is, ha a lemondás az első bájt előtt
  /// jön. Ezért `StreamController`, nem `async*`: egy generátor törzse az
  /// első futása előtti lemondásnál a `finally`-ig sem jutna el.
  Stream<List<int>> read() {
    final controller = StreamController<List<int>>();
    StreamSubscription<List<int>>? source;
    // Egy takarítási hiba se hagyja nyitva a választ.
    Future<void> finish() async {
      try {
        await _releaseOnce();
      } finally {
        await controller.close();
      }
    }

    controller
      ..onListen = () {
        source = _file.openRead().listen(
          controller.add,
          onError: (Object error, StackTrace stackTrace) {
            controller.addError(error, stackTrace);
            unawaited(finish());
          },
          onDone: () => unawaited(finish()),
          cancelOnError: true,
        );
      }
      ..onPause = () {
        source?.pause();
      }
      ..onResume = () {
        source?.resume();
      }
      ..onCancel = () async {
        try {
          await source?.cancel();
        } finally {
          await _releaseOnce();
        }
      };
    return controller.stream;
  }

  // Egyszer fut; a későbbi hívó is a futó takarítás végét várja meg.
  Future<void> _releaseOnce() => _releasing ??= _release();
}
