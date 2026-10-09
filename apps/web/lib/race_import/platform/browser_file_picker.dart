import 'dart:async';
import 'dart:js_interop';

import 'package:foretack_web/race_import/picked_file.dart';
import 'package:foretack_web/race_import/platform/browser_picked_file.dart';
import 'package:web/web.dart' as web;

/// Egy fájl választása a böngésző saját párbeszédével (ADR 0048
/// Addendum 4 K19).
///
/// Egy rejtett `<input type="file">` nyílik. A `change` esemény a
/// választott fájllal, a `cancel` esemény `null`-lal zárja. A `cancel`-t
/// egy régebbi böngésző nem küldi: ott a megszakított választás Future-je
/// nyitva marad, de a dialógus nem vár rá, egy újabb választás pedig új
/// mezőt nyit.
///
/// Szűrő (`accept`) nincs: a `-wal` fájlnak nincs kiterjesztése.
Future<PickedFile?> pickBrowserFile() {
  final completer = Completer<PickedFile?>();
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..style.setProperty('display', 'none');
  // A Safari csak a dokumentumban álló mezőn nyitja meg a párbeszédet.
  web.document.body?.appendChild(input);

  void finish(PickedFile? file) {
    if (completer.isCompleted) return;
    completer.complete(file);
    input.remove();
  }

  input
    ..addEventListener(
      'change',
      ((web.Event _) {
        final files = input.files;
        final file = files == null || files.length == 0 ? null : files.item(0);
        finish(file == null ? null : BrowserPickedFile(file));
      }).toJS,
    )
    ..addEventListener('cancel', ((web.Event _) => finish(null)).toJS)
    ..click();
  return completer.future;
}
