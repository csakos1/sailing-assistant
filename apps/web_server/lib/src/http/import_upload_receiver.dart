import 'dart:io';

import 'package:http_parser/http_parser.dart';
import 'package:meta/meta.dart';
import 'package:mime/mime.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';
import 'package:shelf/shelf.dart';

/// Az import feltöltött fájljai a lemezen; a hiányzó mező `null`.
@immutable
final class ReceivedImportUpload {
  /// Feltöltés a [database] fő fájllal és az opcionális [wal]-lal.
  const ReceivedImportUpload({this.database, this.wal});

  /// A `database` mező tartalma, ha érkezett.
  final File? database;

  /// A `wal` mező tartalma, ha érkezett.
  final File? wal;
}

/// A `POST /api/imports` multipart-törzsének fogadása fájlokba (ADR 0047
/// Addendum 3 C2).
///
/// A részeket streamelve, visszanyomással (`addStream`) írja a céljukba,
/// így a teljes feltöltés soha nincs a memóriában: a valódi szezon-DB
/// 1,7 GB, a VPS-en 2 GB RAM van. A `limitBytes` a beolvasott bájtok
/// összegére vonatkozik (C4).
///
/// Az ideiglenes könyvtárat a hívó birtokolja és takarítja: itt nincs
/// `finally`-törlés, mert sikeres fogadás után a fájlokra még szükség van.
class ImportUploadReceiver {
  /// Fogadó legfeljebb [limitBytes] bájtos feltöltéshez.
  const ImportUploadReceiver({required int limitBytes})
    : _limitBytes = limitBytes;

  final int _limitBytes;

  /// A [request] multipart-törzsének kiírása a [targetDirectory]-ba.
  Future<Result<ReceivedImportUpload, ApiError>> call(
    Request request,
    Directory targetDirectory,
  ) async {
    final boundary = _boundaryOf(request.headers['content-type']);
    if (boundary == null) {
      return const Err(MalformedRequest(_expectedMultipart));
    }
    final declaredLength = request.contentLength;
    if (declaredLength != null && declaredLength > _limitBytes) {
      return Err(PayloadTooLarge(_limitBytes));
    }

    final received = <String, File>{};
    var receivedBytes = 0;
    try {
      final parts = request.read().transform(
        MimeMultipartTransformer(boundary),
      );
      await for (final part in parts) {
        final field = _fieldNameOf(part.headers['content-disposition']);
        if (field == null ||
            !_knownFields.contains(field) ||
            received.containsKey(field)) {
          return Err(MalformedRequest(_unexpectedField(field)));
        }
        final file = File('${targetDirectory.path}/upload-$field');
        received[field] = file;
        final counted = part.map((chunk) {
          receivedBytes += chunk.length;
          if (receivedBytes > _limitBytes) throw const _LimitExceeded();
          return chunk;
        });
        final sink = file.openWrite();
        try {
          await sink.addStream(counted);
        } finally {
          await sink.close();
        }
      }
    } on _LimitExceeded {
      return Err(PayloadTooLarge(_limitBytes));
    } on MimeMultipartException {
      // Csonka törzs: jellemzően a kliens megszakította a feltöltést.
      return const Err(MalformedRequest(_expectedMultipart));
    }

    return Ok(
      ReceivedImportUpload(
        database: received[importDatabaseField],
        wal: received[importWalField],
      ),
    );
  }

  static String? _boundaryOf(String? contentType) {
    if (contentType == null) return null;
    try {
      final mediaType = MediaType.parse(contentType);
      if (mediaType.mimeType != 'multipart/form-data') return null;
      final boundary = mediaType.parameters['boundary'];
      return boundary == null || boundary.isEmpty ? null : boundary;
    } on FormatException {
      return null;
    }
  }

  // A `filename=` is tartalmazza a `name=` szöveget, ezért a minta a
  // paraméter elejéhez (sorkezdet vagy pontosvessző) horgonyoz.
  static final RegExp _namePattern = RegExp(r'(?:^|;)\s*name="([^"]*)"');

  static String? _fieldNameOf(String? contentDisposition) {
    if (contentDisposition == null) return null;
    return _namePattern.firstMatch(contentDisposition)?.group(1);
  }

  static const Set<String> _knownFields = {importDatabaseField, importWalField};

  static const _expectedMultipart = DecodeError(
    path: r'$multipart',
    expected: 'complete multipart/form-data body with a boundary',
  );

  static DecodeError _unexpectedField(String? field) => DecodeError(
    path: '\$multipart.${field ?? '?'}',
    expected:
        'one "$importDatabaseField" and at most one "$importWalField" field',
  );
}

// Belső jelzés a számláló streamből: a korlát túllépése. Nem hiba a
// programban, ezért nem Error, és a fogadón kívül nem látszik.
final class _LimitExceeded implements Exception {
  const _LimitExceeded();
}
