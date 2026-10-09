import 'dart:io';

/// Az export munkakönyvtárainak előtagja a `--temp-root` alatt.
const String exportDirectoryPrefix = 'foretack-export-';

/// A [tempRoot] alatti árva export-könyvtárak törlése (ADR 0050 Addendum 3
/// G2): egy összeomlott vagy leállított szerver maradéka. Induláskor fut,
/// amikor biztosan nincs folyamatban export. A visszatérés a törölt
/// könyvtárak száma.
Future<int> removeStaleExportDirectories(Directory tempRoot) async {
  if (!tempRoot.existsSync()) return 0;
  var removed = 0;
  await for (final entity in tempRoot.list()) {
    if (entity is! Directory) continue;
    final name = entity.uri.pathSegments.lastWhere(
      (segment) => segment.isNotEmpty,
      orElse: () => '',
    );
    if (!name.startsWith(exportDirectoryPrefix)) continue;
    await entity.delete(recursive: true);
    removed++;
  }
  return removed;
}
