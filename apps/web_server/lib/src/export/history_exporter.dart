import 'dart:convert';
import 'dart:io';

import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';
import 'package:web_server/src/export/database_snapshot.dart';
import 'package:web_server/src/export/export_bundle.dart';
import 'package:web_server/src/export/export_layout.dart';
import 'package:web_server/src/export/export_readme.dart';
import 'package:web_server/src/export/history_json_writer.dart';
import 'package:web_server/src/export/stale_export_cleanup.dart';
import 'package:web_server/src/export/tar_entry.dart';
import 'package:web_server/src/export/tar_stream.dart';
import 'package:web_server/src/serial_lock.dart';
import 'package:web_server/src/server_log.dart';

/// Egy DB konzisztens másolata a megadott útvonalra (`VACUUM INTO`).
typedef DatabaseSnapshotter = Future<void> Function(String targetPath);

/// A teljes export (ADR 0050 D8 + Addendum 3).
///
/// Menete: a közös zár alatt a két DB másolata (G3), a zár nélkül a JSON a
/// másolatokból, majd a tar.gz a munkakönyvtárba (G2). A kész fájlt az
/// [ExportBundle] streameli, és a végén takarít. Egyszerre egy export fut,
/// a második [ExportInProgress]-t kap (G4).
final class HistoryExporter {
  /// Exportáló a [tempRoot] munkaterülettel és a közös [lock] zárral.
  HistoryExporter({
    required Directory tempRoot,
    required SerialLock lock,
    required DatabaseSnapshotter snapshotArchive,
    required DatabaseSnapshotter snapshotWebDatabase,
    required SnapshotOpener openSnapshot,
    required int archiveSchemaVersion,
    required int webSchemaVersion,
    required String serverVersion,
    File? stwCorrections,
    DateTime Function() now = DateTime.now,
    ServerLog log = ignoreServerLog,
  }) : _tempRoot = tempRoot,
       _lock = lock,
       _snapshotArchive = snapshotArchive,
       _snapshotWebDatabase = snapshotWebDatabase,
       _openSnapshot = openSnapshot,
       _archiveSchemaVersion = archiveSchemaVersion,
       _webSchemaVersion = webSchemaVersion,
       _serverVersion = serverVersion,
       _stwCorrections = stwCorrections,
       _now = now,
       _log = log;

  final Directory _tempRoot;
  final SerialLock _lock;
  final DatabaseSnapshotter _snapshotArchive;
  final DatabaseSnapshotter _snapshotWebDatabase;
  final SnapshotOpener _openSnapshot;
  final int _archiveSchemaVersion;
  final int _webSchemaVersion;
  final String _serverVersion;
  final File? _stwCorrections;
  final DateTime Function() _now;
  final ServerLog _log;

  // Az építés kezdetétől a streamelés végéig foglalt (G4).
  bool _isBusy = false;

  /// Egy új export, vagy [ExportInProgress], ha egy másik még tart.
  ///
  /// Hiba esetén a munkakönyvtár törlődik, a hiba továbbmegy (500).
  Future<Result<ExportBundle, ExportInProgress>> call() async {
    if (_isBusy) return const Err(ExportInProgress());
    _isBusy = true;
    Directory? workDirectory;
    var isHandedOver = false;
    try {
      final directory = await _tempRoot.createTemp(exportDirectoryPrefix);
      workDirectory = directory;
      final bundle = await _build(directory);
      isHandedOver = true;
      return Ok(bundle);
    } finally {
      if (!isHandedOver) {
        _isBusy = false;
        if (workDirectory != null) await _remove(workDirectory);
      }
    }
  }

  Future<ExportBundle> _build(Directory workDirectory) async {
    final exportedAt = _now().toUtc();
    final (:archiveCopy, :webCopy) = await _takeSnapshot(workDirectory);
    final historyJson = File(
      '${workDirectory.path}/$exportHistoryJsonFileName',
    );
    final raceCount = await _writeHistoryJson(
      archiveCopy: archiveCopy,
      webCopy: webCopy,
      target: historyJson,
      exportedAt: exportedAt,
    );
    _ensureClosed(archiveCopy);
    _ensureClosed(webCopy);

    final baseName = exportBaseName(exportedAt);
    final stwEntry = await _stwCorrectionsEntry(baseName);
    final archiveFile = File('${workDirectory.path}/$baseName.tar.gz');
    await _pack(
      target: archiveFile,
      entries: [
        _readmeEntry(
          baseName,
          exportedAt: exportedAt,
          raceCount: raceCount,
          hasStwCorrections: stwEntry != null,
        ),
        await _fileEntry(baseName, exportHistoryJsonFileName, historyJson),
        await _fileEntry(baseName, exportArchiveFileName, archiveCopy),
        await _fileEntry(baseName, exportWebDatabaseFileName, webCopy),
        ?stwEntry,
      ],
      exportedAt: exportedAt,
    );
    _log('export: $baseName.tar.gz, $raceCount verseny');

    return ExportBundle(
      fileName: '$baseName.tar.gz',
      length: await archiveFile.length(),
      file: archiveFile,
      release: () async {
        _isBusy = false;
        await _remove(workDirectory);
      },
    );
  }

  // A zár alatt csak a két másolat készül (G3): minden író ugyanezt a zárat
  // használja, így a két fájl ugyanazt a pillanatot rögzíti.
  Future<({File archiveCopy, File webCopy})> _takeSnapshot(
    Directory workDirectory,
  ) async {
    final directory = await Directory(
      '${workDirectory.path}/snapshot',
    ).create();
    final archiveCopy = File('${directory.path}/$exportArchiveFileName');
    final webCopy = File('${directory.path}/$exportWebDatabaseFileName');
    await _lock.run(() async {
      await _snapshotArchive(archiveCopy.path);
      await _snapshotWebDatabase(webCopy.path);
    });
    return (archiveCopy: archiveCopy, webCopy: webCopy);
  }

  // A korrekció-fájl az export pillanatában olvasva (ADR 0052 D9). Ha nem
  // olvasható, az export nélküle készül el: a polár ilyenkor amúgy sem
  // elérhető, az adat mentése fontosabb.
  Future<TarEntry?> _stwCorrectionsEntry(String baseName) async {
    final file = _stwCorrections;
    if (file == null) return null;
    try {
      return TarEntry.bytes(
        name: '$baseName/$exportStwCorrectionsFileName',
        bytes: await file.readAsBytes(),
      );
    } on FileSystemException catch (error) {
      _log('export: az STW-korrekció nem olvasható, kimarad: $error');
      return null;
    }
  }

  TarEntry _readmeEntry(
    String baseName, {
    required DateTime exportedAt,
    required int raceCount,
    required bool hasStwCorrections,
  }) => TarEntry.bytes(
    name: '$baseName/$exportReadmeFileName',
    bytes: utf8.encode(
      exportReadme(
        exportedAt: exportedAt,
        raceCount: raceCount,
        serverVersion: _serverVersion,
        archiveSchemaVersion: _archiveSchemaVersion,
        webSchemaVersion: _webSchemaVersion,
        hasStwCorrections: hasStwCorrections,
      ),
    ),
  );

  Future<TarEntry> _fileEntry(String baseName, String name, File file) =>
      TarEntry.file(name: '$baseName/$name', file: file);

  // A tar a gzipen át a fájlba; mindhárom lépés tiszteli a visszanyomást.
  Future<void> _pack({
    required File target,
    required List<TarEntry> entries,
    required DateTime exportedAt,
  }) => gzip.encoder
      .bind(tarStream(entries, modified: exportedAt))
      .pipe(target.openWrite());

  Future<int> _writeHistoryJson({
    required File archiveCopy,
    required File webCopy,
    required File target,
    required DateTime exportedAt,
  }) async {
    final snapshot = await _openSnapshot(
      archiveCopy: archiveCopy,
      webCopy: webCopy,
    );
    try {
      final sink = target.openWrite();
      try {
        return await HistoryJsonWriter(
          readSummaries: snapshot.services.summaries.call,
          readDetail: snapshot.services.details.call,
          log: _log,
        ).write(sink, exportedAt: exportedAt);
      } finally {
        await sink.close();
      }
    } finally {
      await snapshot.close();
    }
  }

  // A takarítás hibája nem fedheti el az eredeti hibát, és nem szakíthatja
  // meg a már elküldött letöltést; az árva könyvtárat induláskor törli a
  // szerver (G2).
  Future<void> _remove(Directory workDirectory) async {
    try {
      await workDirectory.delete(recursive: true);
    } on FileSystemException catch (error) {
      _log('export: a munkakönyvtár nem törölhető: $error');
    }
  }

  // A lezárt másolat mellett nem maradhat napló: a csomagba csak a fő fájl
  // kerül, egy visszaíratlan -wal adatvesztés lenne.
  void _ensureClosed(File database) {
    for (final suffix in const ['-wal', '-journal']) {
      final journal = File('${database.path}$suffix');
      if (journal.existsSync() && journal.lengthSync() > 0) {
        throw StateError('export: ${journal.path} left after close');
      }
    }
  }
}
