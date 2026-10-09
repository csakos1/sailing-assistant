import 'dart:io';

import 'package:args/args.dart';
import 'package:web_server/src/auth/cli/describe_devices.dart';
import 'package:web_server/src/auth_db/cli_auth_database.dart';
import 'package:web_server/src/auth_db/device_repository.dart';
import 'package:web_server/src/auth_db/device_revocation.dart';
import 'package:web_server/src/cli/missing_files.dart';

// Egy eszköz visszavonása a VPS-en (ADR 0051 D3), például egy elveszett
// telefoné, ha az appból már nem lehet. A --device nélkül kilistázza az
// eszközöket az azonosítójukkal; a szerver futhat közben.
//
//   dart run web_server:revoke_device \
//     --auth-db /var/lib/foretack/auth.sqlite [--device <id>]
Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('auth-db', help: 'A hitelesítés SQLite-fájlja (kötelező).')
    ..addOption('device', help: 'A visszavonandó eszköz azonosítója.');

  final String authDbPath;
  final String? deviceId;
  try {
    final options = parser.parse(arguments);
    authDbPath =
        options.option('auth-db') ??
        (throw const FormatException('--auth-db: kötelező kapcsoló'));
    deviceId = options.option('device');
  } on FormatException catch (error) {
    stderr
      ..writeln(error.message)
      ..writeln(parser.usage);
    exitCode = 64;
    return;
  }

  final missing = missingFileLines({'auth-db': authDbPath});
  if (missing.isNotEmpty) {
    missing.forEach(stderr.writeln);
    exitCode = 66;
    return;
  }

  final authDatabase = openAuthDatabaseForCli(authDbPath);
  try {
    final devices = DeviceRepository(authDatabase);
    if (deviceId == null) {
      describeDevices(await devices.listAll()).forEach(stdout.writeln);
      return;
    }
    final now = DateTime.now().toUtc();
    // A munkamenetei és a tokenjei is lezárulnak (ADR 0051 Addendum 5 M7).
    final revoke = deviceRevokerOver(authDatabase);
    if (await revoke(deviceId, now: now)) {
      stdout.writeln('Visszavonva: $deviceId');
    } else {
      stderr.writeln('Nincs ilyen aktív eszköz: $deviceId');
      exitCode = 65;
    }
  } finally {
    await authDatabase.close();
  }
}
