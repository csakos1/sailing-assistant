import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:phone/features/race_detail/export/track_export_content.dart';
import 'package:phone/features/race_detail/export/track_export_error.dart';
import 'package:phone/features/race_detail/export/track_export_file_name.dart';
import 'package:phone/features/race_detail/export/track_export_renderer.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared/shared.dart';

/// Kirendereli, temp fájlba írja és megosztja a track-képet.
///
/// A három lépés három hibaágat kap (A1-D7): a raszterizálás, a fájlírás és
/// a share sheet külön-külön elbukhat, és a felhasználónak mást kell
/// mondanunk mindháromról. Ezért `Result`, nem kivétel.
///
/// A megosztás EREDMÉNYÉT nem vizsgáljuk: ha a felhasználó elveti a share
/// sheetet, az nem hiba, hanem döntés. Csak az számít, hogy a felület
/// egyáltalán elindult-e.
///
/// Sikeres ágon a temp fájlt visszaadjuk — a rendszer takarítja, mi nem
/// töröljük, mert a megosztó alkalmazás még olvashatja.
Future<Result<File, TrackExportError>> exportAndShareTrackImage({
  required RenderRepaintBoundary boundary,
  required TrackExportContent content,
  required String raceName,
  required DateTime? startedAt,
}) async {
  final Uint8List bytes;
  try {
    bytes = await _renderPngBytes(boundary, content);
  } on Object catch (error) {
    return Err(CaptureFailed(error));
  }

  final File file;
  try {
    final directory = await getTemporaryDirectory();
    final name = trackExportFileName(
      raceName: raceName,
      startedAt: startedAt,
    );
    file = await File('${directory.path}/$name').writeAsBytes(bytes);
  } on Object catch (error) {
    return Err(StorageUnavailable(error));
  }

  try {
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
  } on Object catch (error) {
    return Err(ShareFailed(error));
  }

  return Ok(file);
}

/// A kirenderelt képet PNG-bájtokká alakítja, majd elengedi a nyers képet.
Future<Uint8List> _renderPngBytes(
  RenderRepaintBoundary boundary,
  TrackExportContent content,
) async {
  final image = await renderTrackExportImage(
    boundary: boundary,
    content: content,
  );
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) {
      throw StateError('The rendered export image produced no PNG bytes.');
    }
    return data.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}
