import 'dart:typed_data';

import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';

/// A kérés-törzs beolvasása a memóriába, legfeljebb [limitBytes] bájtig
/// (ADR 0047 Addendum 3 C4).
///
/// Csak kis törzsekre való (az annotáció 64 KiB); a nagy importot a
/// multipart-fogadó streameli fájlba. A korlát a ténylegesen beolvasott
/// bájtokra vonatkozik: a `Content-Length` hiányozhat, vagy hazudhat. Ha
/// a fejléc már eleve túl nagyot jelez, a törzset el sem kezdjük olvasni.
Future<Result<List<int>, PayloadTooLarge>> readBoundedBody(
  Stream<List<int>> body, {
  required int limitBytes,
  int? declaredLength,
}) async {
  if (declaredLength != null && declaredLength > limitBytes) {
    return Err(PayloadTooLarge(limitBytes));
  }
  final builder = BytesBuilder(copy: false);
  // A break megszakítja a feliratkozást, így a túl nagy törzs maradékát
  // már nem olvassuk be.
  await for (final chunk in body) {
    if (builder.length + chunk.length > limitBytes) {
      return Err(PayloadTooLarge(limitBytes));
    }
    builder.add(chunk);
  }
  return Ok(builder.takeBytes());
}
