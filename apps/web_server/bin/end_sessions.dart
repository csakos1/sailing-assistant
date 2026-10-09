import 'dart:io';

import 'package:args/args.dart';
import 'package:web_server/src/auth/auth_lifetimes.dart';
import 'package:web_server/src/auth/cli/describe_sessions.dart';
import 'package:web_server/src/auth/session_closer.dart';
import 'package:web_server/src/auth_db/auth_database.dart';
import 'package:web_server/src/auth_db/cli_auth_database.dart';
import 'package:web_server/src/auth_db/session_repository.dart';
import 'package:web_server/src/cli/missing_files.dart';

// Webes munkamenetek lezárása a VPS-en (ADR 0052 D10), például ha a
// telefon is és egy helyreállító kód is idegen kézbe került: a tartalék
// belépéssel nyitott munkamenetet a revoke_device nem zárja le. A
// kapcsolók nélkül kilistázza az élő munkameneteket; a szerver futhat
// közben.
//
//   dart run web_server:end_sessions \
//     --auth-db /var/lib/foretack/auth.sqlite \
//     [--session <id> | --user <userId>]
Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('auth-db', help: 'A hitelesítés SQLite-fájlja (kötelező).')
    ..addOption('session', help: 'A lezárandó munkamenet azonosítója.')
    ..addOption(
      'user',
      help: 'A fiók azonosítója, amelynek minden munkamenete lezárul.',
    );

  final String authDbPath;
  final String? sessionId;
  final String? userId;
  try {
    final options = parser.parse(arguments);
    authDbPath =
        options.option('auth-db') ??
        (throw const FormatException('--auth-db: kötelező kapcsoló'));
    sessionId = options.option('session');
    userId = options.option('user');
    if (sessionId != null && userId != null) {
      throw const FormatException(
        '--session és --user: egyszerre csak az egyik adható meg',
      );
    }
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
    exitCode = await _run(authDatabase, sessionId: sessionId, userId: userId);
  } finally {
    await authDatabase.close();
  }
}

Future<int> _run(
  AuthDatabase database, {
  required String? sessionId,
  required String? userId,
}) async {
  final closer = SessionCloser(database);
  if (sessionId != null) {
    if (await closer.closeSession(sessionId)) {
      stdout.writeln('Lezárva: $sessionId');
      return 0;
    }
    stderr.writeln('Nincs ilyen munkamenet: $sessionId');
    return 65;
  }
  if (userId != null) {
    final count = await closer.closeUserSessions(userId);
    if (count == null) {
      stderr.writeln('Nincs ilyen fiók: $userId');
      return 65;
    }
    // A lejárt, még nem takarított sorok is beleszámítanak.
    stdout.writeln(
      'Lezárva: $count munkamenet ($userId), a lejártakkal együtt',
    );
    return 0;
  }
  final now = DateTime.now().toUtc();
  final sessions = await SessionRepository(database).listLive(
    idleCutoff: now.subtract(sessionIdleTimeout),
    createdCutoff: now.subtract(sessionMaximumLifetime),
  );
  describeSessions(sessions).forEach(stdout.writeln);
  return 0;
}
