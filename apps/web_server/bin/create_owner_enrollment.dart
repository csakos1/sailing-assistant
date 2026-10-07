import 'dart:io';

import 'package:args/args.dart';
import 'package:drift/native.dart';
import 'package:shared/shared.dart';
import 'package:web_server/src/auth/cli/describe_owner_enrollment.dart';
import 'package:web_server/src/auth/owner_enrollment.dart';
import 'package:web_server/src/auth/random_bytes.dart';
import 'package:web_server/src/auth_db/auth_database.dart';
import 'package:web_server/src/auth_db/enrollment_repository.dart';
import 'package:web_server/src/auth_db/user_repository.dart';

// Az owner telefonjának regisztrációs QR-ja (ADR 0051 D3 + Addendum 2 J8).
// Az első futás létrehozza az auth.sqlite-ot; elveszett telefon után is
// ezzel jön az új. A szerver felhasználójaként futtasd, hogy a DB-fájl az
// övé legyen. A QR-szöveg a stdout-ra megy, minden más a stderr-re:
//
//   dart run web_server:create_owner_enrollment \
//     --auth-db /var/lib/foretack/auth.sqlite \
//     --origin https://archivum.example.hu [--name Ákos] \
//     | qrencode -t ansiutf8
Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('auth-db', help: 'A hitelesítés SQLite-fájlja (kötelező).')
    ..addOption('origin', help: 'A web kanonikus origója (kötelező).')
    ..addOption('name', help: 'Az első tulajdonos neve (csak először).');

  final String authDbPath;
  final String origin;
  final String? name;
  try {
    final options = parser.parse(arguments);
    authDbPath = _requiredOption(options, 'auth-db');
    origin = _requiredOption(options, 'origin');
    name = options.option('name');
  } on FormatException catch (error) {
    stderr
      ..writeln(error.message)
      ..writeln(parser.usage);
    exitCode = 64;
    return;
  }

  // A DB-fájlt az első futás hozza létre, a könyvtárát viszont nem.
  final directory = File(authDbPath).parent;
  if (!directory.existsSync()) {
    stderr.writeln('--auth-db: a könyvtár nem létezik: ${directory.path}');
    exitCode = 66;
    return;
  }

  // Az első futás a fájlt csak a tulajdonosának olvashatóan hozza létre:
  // kulcsok, token- és jelszó-hash-ek lesznek benne (Addendum 2 J8).
  final authDbFile = File(authDbPath);
  if (!_isPrivateFile(authDbFile)) {
    stderr.writeln('--auth-db: a fájl nem hozható létre 0600-s joggal.');
    exitCode = 73;
    return;
  }

  final authDatabase = AuthDatabase(NativeDatabase(authDbFile));
  try {
    final result = await issueOwnerEnrollment(
      users: UserRepository(authDatabase),
      enrollments: EnrollmentRepository(authDatabase),
      origin: origin,
      name: name,
      now: DateTime.now().toUtc(),
      randomBytes: secureRandomBytes,
    );
    switch (result) {
      case Ok(:final value):
        stdout.writeln(value.qrText);
        describeOwnerEnrollment(value).forEach(stderr.writeln);
      case Err(:final error):
        stderr.writeln(describeOwnerEnrollmentError(error));
        exitCode = 65;
    }
  } finally {
    await authDatabase.close();
  }
}

// Létrehozza a fájlt, ha nincs, és csak a tulajdonosnak hagy rajta jogot.
// Egy kézzel, lazább joggal előre létrehozott fájlt is szigorít.
bool _isPrivateFile(File file) {
  try {
    if (!file.existsSync()) file.createSync();
    if (file.statSync().mode & 0x3F == 0) return true;
    return Process.runSync('chmod', ['600', file.path]).exitCode == 0;
  } on FileSystemException {
    return false;
  }
}

String _requiredOption(ArgResults options, String name) =>
    options.option(name) ??
    (throw FormatException('--$name: kötelező kapcsoló'));
