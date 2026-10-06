import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foretack_web/app/platform/file_download.dart';

/// Egy letöltés indítása a megadott címről (az oldalhoz képest).
typedef FileDownloader = void Function(String href);

/// A böngésző letöltése (ADR 0050 Addendum 3 G2); a tesztek felülírják,
/// hogy a kért címet lássák.
final Provider<FileDownloader> fileDownloadProvider = Provider<FileDownloader>(
  (ref) => startFileDownload,
);
